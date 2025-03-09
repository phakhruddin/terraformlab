# Module to create a file with given filename, content, and permission
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
  default     = "644" # Default permission if not specified
}

variable "bu" {
  description = "The business unit (subdirectory)"
  type        = string
}

resource "local_file" "file" {
  filename        = "${path.module}/../../result/${var.bu}/${var.filename}"
  content         = var.content
  file_permission = var.permission
}

output "created_file" {
  value = local_file.file.filename
}
