packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "ubuntu" {
  image  = "ubuntu:22.04"
  commit = true
  pull   = false
}

source "docker" "alpine" {
  image  = "alpine:3.19"
  commit = true
  pull   = false
}

build {
  name    = "multi-os"
  sources = [
    "source.docker.ubuntu",
    "source.docker.alpine",
  ]

  # Copier le script show-info.sh dans les deux images
  provisioner "file" {
    source      = "show-info.sh"
    destination = "/usr/local/bin/show-info.sh"
  }

  # Installer curl et wget sur Ubuntu
  provisioner "shell" {
    only = ["docker.ubuntu"]
    inline = [
      "apt-get update -y",
      "apt-get install -y curl wget",
    ]
  }

  # Installer curl et wget sur Alpine
  provisioner "shell" {
    only = ["docker.alpine"]
    inline = [
      "apk add --no-cache curl wget",
    ]
  }

  # Générer system-info.txt et rendre show-info.sh exécutable (commun aux deux)
  provisioner "shell" {
    inline = [
      "uname -a > /system-info.txt",
      "echo '' >> /system-info.txt",
      "cat /etc/os-release >> /system-info.txt",
      "chmod +x /usr/local/bin/show-info.sh",
    ]
  }

  post-processor "docker-tag" {
    repository = "multi-os-ubuntu"
    tags       = ["latest"]
    only       = ["docker.ubuntu"]
  }

  post-processor "docker-tag" {
    repository = "multi-os-alpine"
    tags       = ["latest"]
    only       = ["docker.alpine"]
  }
}
