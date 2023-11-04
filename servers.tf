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

  # Recreate inventory on each run, create build server first
  provisioner "local-exec" {
    command = <<-EOS1
				tee /etc/ansible/hosts <<-EOS2
					[build]
					${self.network_interface.0.nat_ip_address} ansible_user=ubuntu ansible_ssh_common_args="-o StrictHostKeyChecking=no -o ConnectionAttempts=20"
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

  # Append to inventory when creating staging server
  provisioner "local-exec" {
    command = <<-EOS1
				tee -a /etc/ansible/hosts <<-EOS2
					[staging]
					${self.network_interface.0.nat_ip_address} ansible_user=ubuntu ansible_ssh_common_args="-o StrictHostKeyChecking=no -o ConnectionAttempts=20"
				EOS2
	EOS1
  }

  depends_on = [yandex_compute_instance.build]

}