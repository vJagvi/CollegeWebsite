# variables.tf

variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  default     = "my-keypair"
}

variable "ecr_repo_url" {
  description = "ECR repository URL of the Docker image"
  default     = "387056640483.dkr.ecr.us-east-1.amazonaws.com/college-website:latest"
}

variable "security_group_name" {
  description = "Security group name for EC2 instance"
  default     = "jenkins-ec2-sg"
}
