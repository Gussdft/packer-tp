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
  ami_name               = "learn-packer-nginx-healthcheck-${local.timestamp}"
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
  name    = "learn-packer-nginx-healthcheck"
  sources = ["source.amazon-ebs.ubuntu"]

  # Installer Nginx
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx curl",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
    ]
  }

  # Copier la page HTML
  provisioner "file" {
    source      = "index.html"
    destination = "/tmp/index.html"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/index.html /var/www/html/index.html",
      "sudo systemctl restart nginx",
    ]
  }

  # Tests et healthcheck
  provisioner "shell" {
    inline = [
      # 1. Vérifier la configuration Nginx
      "echo '=== Test 1 : Validation de la configuration Nginx ==='",
      "sudo nginx -t",

      # 2. Vérifier le statut de Nginx
      "echo '=== Test 2 : Statut du service Nginx ==='",
      "sudo systemctl status nginx --no-pager",

      # 3. Healthcheck HTTP sur le port 80
      "echo '=== Test 3 : Healthcheck HTTP port 80 ==='",
      "curl -f http://localhost:80 && echo 'Healthcheck OK : Nginx repond sur le port 80.' || (echo 'Healthcheck FAILED' && exit 1)",
    ]
  }
}
