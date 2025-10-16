variable "aws_region" {
  description = "AWS Region to deploy resources"
  default     = "us-east-1"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "ecr_repo" {
  description = "ECR repository URI with tag"
  type        = string
}
