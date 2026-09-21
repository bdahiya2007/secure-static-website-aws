variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket (also used as part of the website URL)"
  type        = string
}

variable "environment" {
  description = "Environment tag applied to resources (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project" {
  type        = string
  description = "Project name used for resource naming/tagging"
}

variable "index_document" {
  description = "Filename of the website's index/home page"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Filename of the website's error page"
  type        = string
  default     = "error.html"
}
