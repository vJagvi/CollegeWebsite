provider "aws" {
  region = var.region
}

# ------------------------------
# IAM Role for EC2 to Access ECR + SSM
# ------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach policies
resource "aws_iam_role_policy_attachment" "ecr_readonly_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ------------------------------
# Security Group
# ------------------------------
resource "aws_security_group" "web_sg" {
  name        = var.security_group_name
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-ec2-sg"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------
# Latest Amazon Linux 2 AMI
# ------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# ------------------------------
# EC2 Instance (One-time setup)
# ------------------------------
resource "aws_instance" "web" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  security_groups      = [aws_security_group.web_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl enable docker
              systemctl start docker
              usermod -a -G docker ec2-user
              EOF

  tags = {
    Name = "CollegeWebsite-EC2"
  }

  # Don’t recreate instance when AMI or user_data changes
  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# ------------------------------
# Trigger Container Update via SSM (Windows Jenkins Safe)
# ------------------------------
resource "null_resource" "update_container_via_ssm" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = <<-EOT
      $CommandFile = "update_container.ps1"
      $CommandText = @'
aws ssm send-command `
  --region ${var.region} `
  --instance-ids ${aws_instance.web.id} `
  --document-name "AWS-RunShellScript" `
  --comment "Terraform triggered Docker update from ECR" `
  --parameters '{"commands":["aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_repo_url}:latest","docker pull ${var.ecr_repo_url}:latest","docker stop college-website || true","docker rm college-website || true","docker run -d --name college-website -p 80:80 ${var.ecr_repo_url}:latest"]}'
'@

      Set-Content -Path $CommandFile -Value $CommandText
      Write-Host "✅ Executing PowerShell SSM command file..."
      powershell -ExecutionPolicy Bypass -File $CommandFile
    EOT
  }
}

