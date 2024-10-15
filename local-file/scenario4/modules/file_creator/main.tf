# Module to create a file with given filename, content, and permission

resource "local_file" "file" {
  filename       = "${path.module}/../../result/${var.filename}"
  content        = var.content
  file_permission = var.permission
}