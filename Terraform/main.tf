provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group allowing HTTP & SSH
resource "aws_security_group" "web_sg" {
  name        = "jenkins-ec2-sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
}

# IAM Role for EC2 to access ECR and SSM
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.ec2_instance_type
  security_groups      = [aws_security_group.web_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = var.key_name

  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user

    REGION=${var.aws_region}
    REPO=${var.ecr_repo}

    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO
    docker pull $REPO
    docker run -d -p 80:80 $REPO
  EOT

  tags = {
    Name = "CollegeWebsite-EC2"
  }
}
