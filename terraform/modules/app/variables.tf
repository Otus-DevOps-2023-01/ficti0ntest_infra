variable app_disk_image {
description = "Disk image for reddit app"
default = "reddit-app-base"
}
variable "subnet_id" {
  description = "Subnets for modules"
}
variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}
variable "private_key_path" {
  description = "Connection private key file"
}
variable "db_ip" {
  description = "Internal IP DB"
}
