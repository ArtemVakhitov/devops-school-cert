terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-b"
}

locals {
  names = ["build", "staging"]
}

resource "yandex_compute_instance" "terra" {

  for_each = toset(local.names)

  name = each.value
  hostname = each.value

  zone = "ru-central1-b"
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8q5m87s3v0hmp06i5c"
      size = 15
    }
  }

  network_interface {
    subnet_id = "e2lgv5mqm56n8fjkt37q"
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_dsa.pub")}"
  }

}

resource "local_file" "ansible_config" {
  content  = <<-EOF
								[defaults]
								inventory = ./hosts
								EOF
  filename = "${path.root}/ansible.cfg"
}

resource "local_file" "ansible_inventory" {
  content  = <<-EOF
								[build]
								${yandex_compute_instance.terra["build"].network_interface.0.nat_ip_address}
								[staging]
								${yandex_compute_instance.terra["staging"].network_interface.0.nat_ip_address}
								[all:vars]
								ansible_user=ubuntu
								ansible_ssh_common_args="-o StrictHostKeyChecking=no -o ConnectionAttempts=20"
								ansible_become=yes
								ansible_become_user=root
                ansible_ssh_private_key_file=~/.ssh/id_dsa
								EOF
  filename = "${path.root}/hosts"
}

output "build_ip" {
  value = yandex_compute_instance.terra["build"].network_interface.0.nat_ip_address
}

output "staging_ip" {
  value = yandex_compute_instance.terra["staging"].network_interface.0.nat_ip_address
}