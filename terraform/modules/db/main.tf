# terraform {
#   required_providers {
#     yandex = {
#       source = "yandex-cloud/yandex"
#     }
#   }
#   required_version = ">= 0.13"
# }

resource "yandex_compute_instance" "db" {
  name  = "reddit-db"

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat = true
  }

  connection {
    type  = "ssh"
    host  = yandex_compute_instance.db.network_interface[0].nat_ip_address
    user  = "ubuntu"
    agent = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    content     = templatefile("${path.module}/files/mongodb.conf.tmpl", { db_ip = yandex_compute_instance.db.network_interface.0.ip_address})
    destination = "/tmp/mongodb.conf"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
}
