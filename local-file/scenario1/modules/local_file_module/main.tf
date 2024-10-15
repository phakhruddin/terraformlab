# modules/local_file_module/main.tf

variable "business_unit" {
  description = "Name of the business unit"
}

variable "file_content" {
  description = "Content to be written to the file"
}

variable "file_permission" {
  description = "Permissions for the created file"
  default     = "0644"
}

# Create the local file
resource "local_file" "business_file" {
  filename        = "${path.module}/output/${var.business_unit}_file.txt"
  content         = var.file_content
  file_permission = var.file_permission
}
