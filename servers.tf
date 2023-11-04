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

resource "random_string" "sfx" {
  length  = 3
  special = false
  upper   = false
}

resource "yandex_compute_instance" "build" {

  name = "build"
  hostname = "build"

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
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }

  provisioner "local-exec" {
    command = <<-EOS1
				tee -a /etc/ansible/hosts <<-EOS2
					[build.${random_string.sfx.result}]
					${self.network_interface.0.nat_ip_address}
				EOS2
	EOS1
  }
}

resource "yandex_compute_instance" "staging" {

  name = "staging"
  hostname= "staging"

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
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }

  provisioner "local-exec" {
    command = <<-EOS1
				tee -a /etc/ansible/hosts <<-EOS2
					[staging.${random_string.sfx.result}]
					${self.network_interface.0.nat_ip_address}
				EOS2
	EOS1
  }
}