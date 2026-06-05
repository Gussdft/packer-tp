packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "ubuntu" {
  image  = var.docker_image
  commit = true
  pull   = false
}

source "docker" "ubuntu-focal" {
  image  = var.focal_image
  commit = true
  pull   = false
}

build {
  name    = "learn-packer"
  sources = [
    "source.docker.ubuntu",
    "source.docker.ubuntu-focal",
  ]

  provisioner "shell" {
    environment_vars = [
      "FOO=${var.foo_content}",
    ]
    inline = [
      "echo Adding file to Docker Container",
      "echo \"FOO is $FOO\" > example.txt",
    ]
  }

  provisioner "shell" {
    inline = ["echo Running ${var.docker_image} Docker image."]
  }

  post-processor "docker-tag" {
    repository = "learn-packer"
    tags       = var.tags_jammy
    only       = ["docker.ubuntu"]
  }

  post-processor "docker-tag" {
    repository = "learn-packer"
    tags       = var.tags_focal
    only       = ["docker.ubuntu-focal"]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
