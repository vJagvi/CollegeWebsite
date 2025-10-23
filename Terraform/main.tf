provider "aws" {
  region = var.region
}

# ------------------------------
# IAM Role for EC2 to Access ECR
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

# ------------------------------
# Security Group
# ------------------------------
resource "aws_security_group" "web_sg" {
  name        = var.security_group_name
  description = "Allow HTTP, SSH, and Monitoring Ports"

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

  # Monitoring ports for Prometheus stack
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
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
# EC2 Instance
# ------------------------------
resource "aws_instance" "web" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  security_groups      = [aws_security_group.web_sg.name]

  # SSH connection for file provisioner
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/Users/Venkat/Downloads/my-keypair.pem")
    host        = self.public_ip
  }

  # Copy Prometheus config file to EC2
  provisioner "file" {
    source      = "prometheus.yml"
    destination = "/home/ec2-user/prometheus/prometheus.yml"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl enable docker
              systemctl start docker
              usermod -a -G docker ec2-user
              sleep 10

              REGION=${var.region}
              REPO=${var.ecr_repo_url}

              aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO
              docker pull $REPO

              if [ $(docker ps -q -f name=college-website) ]; then
                docker stop college-website
                docker rm college-website
              fi

              docker run -d --name college-website -p 80:80 $REPO

              # ------------------------------
              # Node Exporter
              # ------------------------------
              docker rm -f node_exporter || true
              docker run -d --name node_exporter --network=host prom/node-exporter

              # ------------------------------
              # cAdvisor
              # ------------------------------
              docker rm -f cadvisor || true
              docker run -d --name cadvisor \
                --volume=/:/rootfs:ro \
                --volume=/var/run:/var/run:rw \
                --volume=/sys:/sys:ro \
                --volume=/var/lib/docker/:/var/lib/docker:ro \
                -p 8080:8080 gcr.io/cadvisor/cadvisor:latest

              # ------------------------------
              # Prometheus
              # ------------------------------
              mkdir -p /home/ec2-user/prometheus
              docker rm -f prometheus || true
              docker run -d --name prometheus -p 9090:9090 \
                -v /home/ec2-user/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
                prom/prometheus
              EOF

  tags = {
    Name = "CollegeWebsite-EC2"
  }
}
