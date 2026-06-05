packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# Source AWS AMI
source "amazon-ebs" "ubuntu" {
  ami_name               = "learn-packer-nginx-multi-${local.timestamp}"
  instance_type          = "t2.micro"
  region                 = "us-east-1"
  skip_region_validation = true
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

# Source Docker
source "docker" "ubuntu" {
  image  = "ubuntu:jammy"
  commit = true
  pull   = false
}

build {
  name = "multi-platform-nginx"
  sources = [
    "source.amazon-ebs.ubuntu",
    "source.docker.ubuntu",
  ]

  # Installer Nginx (commun aux deux)
  provisioner "shell" {
    inline = [
      "apt-get update -y || sudo apt-get update -y",
      "apt-get install -y nginx curl || sudo apt-get install -y nginx curl",
    ]
  }

  # Copier la page HTML
  provisioner "file" {
    source      = "index.html"
    destination = "/tmp/index.html"
  }

  provisioner "shell" {
    inline = [
      "mv /tmp/index.html /var/www/html/index.html || sudo mv /tmp/index.html /var/www/html/index.html",
    ]
  }

  # AWS uniquement : activer le service systemd
  provisioner "shell" {
    only = ["amazon-ebs.ubuntu"]
    inline = [
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "sudo nginx -t",
      "curl -f http://localhost:80 && echo 'Healthcheck AWS OK.'",
    ]
  }

  # Docker uniquement : démarrer nginx manuellement pour le healthcheck
  provisioner "shell" {
    only = ["docker.ubuntu"]
    inline = [
      "nginx -g 'daemon off;' &",
      "sleep 2",
      "curl -f http://localhost:80 && echo 'Healthcheck Docker OK.'",
    ]
  }

  # Tagger l'image Docker
  post-processor "docker-tag" {
    repository = "nginx-packer"
    tags       = ["latest"]
    only       = ["docker.ubuntu"]
  }
}
