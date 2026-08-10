variable "project_name" {
  description = "Name prefix used for tagging all resources"
  type        = string
  default     = "shopflow"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}
