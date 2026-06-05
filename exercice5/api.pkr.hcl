packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "node" {
  image  = "node:18"
  commit = true
  pull   = false
}

build {
  name    = "ci-cd-api"
  sources = ["source.docker.node"]

  # Copier le code source dans l'image
  provisioner "file" {
    source      = "app/"
    destination = "/app"
  }

  # Installer les dépendances
  provisioner "shell" {
    inline = [
      "cd /app",
      "npm install",
    ]
  }

  post-processor "docker-tag" {
    repository = "ci-cd-api"
    tags       = ["latest"]
  }
}
