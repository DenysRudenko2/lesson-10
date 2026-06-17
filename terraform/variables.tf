variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "project" {
  description = "Name prefix for resources"
  type        = string
  default     = "mlops-train"
}
