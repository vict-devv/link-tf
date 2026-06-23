variable "name" {
  description = "ECR repository name"
  type        = string
}

variable "image_tag_mutability" {
  description = "Set images' tags mutability, allowing overwrite or enforcing unique values"
  type        = string
  default     = "MUTABLE"
}

variable "keep_image_count" {
  description = "Number of recent images to retain in the lifecycle policy"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to the repository"
  type        = map(string)
  default     = {}
}
