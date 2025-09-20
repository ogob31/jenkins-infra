variable "aws_region" {
  description = "The AWS region to deploy into (e.g., us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}