variable "aws_region" {
  description = "AWS region for the challenge infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name project resources."
  type        = string
  default     = "devops-challenge"
}
