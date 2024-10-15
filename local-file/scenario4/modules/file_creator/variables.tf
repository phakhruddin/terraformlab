variable "filename" {
  description = "The name of the file to be created"
  type        = string
}

variable "content" {
  description = "Content to be written to the file"
  type        = string
}

variable "permission" {
  description = "The permission of the file"
  type        = string
  default     = "644"  # Default file permission
}
