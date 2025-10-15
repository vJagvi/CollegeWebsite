variable "region" {
  default = "us-east-1"
}

variable "ecr_repo_url" {
  default = "387056640483.dkr.ecr.us-east-1.amazonaws.com/college-website"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "my-ec2-key"  # Replace this with your EC2 keypair name in AWS
}
