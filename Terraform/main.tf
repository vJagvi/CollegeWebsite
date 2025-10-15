provider "aws" {
  region = var.region
}

variable "region" {}
variable "ecr_repo_url" {}
variable "instance_type" {}
variable "key_name" {}

resource "aws_security_group" "web_sg" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"

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
}

resource "aws_instance" "web_server" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 in us-east-1
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    amazon-linux-extras install -y awscli

    # Login to ECR and pull image
    REGION=${var.region}
    REPO=${var.ecr_repo_url}

    $(aws ecr get-login --no-include-email --region ${var.region})

    docker pull ${var.ecr_repo_url}:latest
    docker run -d -p 80:80 ${var.ecr_repo_url}:latest
  EOF

  tags = {
    Name = "CollegeWebsite-EC2"
  }
}

output "public_ip" {
  value = aws_instance.web_server.public_ip
}
