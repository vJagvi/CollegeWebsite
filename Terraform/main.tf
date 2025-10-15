# main.tf

provider "aws" {
  region = var.region
}

# Security Group allowing HTTP and SSH
resource "aws_security_group" "web_sg" {
  name        = var.security_group_name
  description = "Allow HTTP and SSH"

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
}

# EC2 instance
resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type           = var.instance_type
  key_name                = var.key_name
  security_groups         = [aws_security_group.web_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker login -u AWS -p $(aws ecr get-login-password --region ${var.region}) ${var.ecr_repo_url}
              docker run -d -p 80:80 ${var.ecr_repo_url}
              EOF

  tags = {
    Name = "CollegeWebsite-EC2"
  }
}
