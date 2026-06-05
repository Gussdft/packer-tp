packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name               = "learn-packer-nginx-${local.timestamp}"
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

build {
  name    = "learn-packer-nginx"
  sources = ["source.amazon-ebs.ubuntu"]

  # Installer Nginx
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
    ]
  }

  # Copier la page HTML statique
  provisioner "file" {
    source      = "index.html"
    destination = "/tmp/index.html"
  }

  # Placer le fichier dans le dossier Nginx
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/index.html /var/www/html/index.html",
      "sudo systemctl restart nginx",
    ]
  }
}
