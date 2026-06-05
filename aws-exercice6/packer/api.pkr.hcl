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

# Source AWS AMI (Node.js sur Ubuntu)
source "amazon-ebs" "ubuntu" {
  ami_name               = "learn-packer-api-${local.timestamp}"
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

# Source Docker (Node.js)
source "docker" "node" {
  image  = "node:18"
  commit = true
  pull   = false
}

build {
  name = "multi-platform-api"
  sources = [
    "source.amazon-ebs.ubuntu",
    "source.docker.node",
  ]

  # Créer le dossier /app sur AWS avant la copie
  provisioner "shell" {
    only = ["amazon-ebs.ubuntu"]
    inline = ["sudo mkdir -p /app && sudo chmod 777 /app"]
  }

  # Copier le code source
  provisioner "file" {
    source      = "app/"
    destination = "/app"
  }

  # AWS : installer Node.js et les dépendances
  provisioner "shell" {
    only = ["amazon-ebs.ubuntu"]
    inline = [
      "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "cd /app && sudo npm install",
      # Créer un service systemd pour démarrer l'API au boot
      "sudo bash -c 'cat > /etc/systemd/system/api.service << EOF\n[Unit]\nDescription=Node.js API\nAfter=network.target\n\n[Service]\nWorkingDirectory=/app\nExecStart=/usr/bin/node src/index.js\nRestart=always\nEnvironment=PORT=3000\n\n[Install]\nWantedBy=multi-user.target\nEOF'",
      "sudo systemctl enable api",
      "sudo systemctl start api",
      "sleep 3",
      # Healthcheck
      "curl -f http://localhost:3000/auth/secret-mysecretphrase && echo 'Healthcheck AWS OK.'",
    ]
  }

  # Docker : installer les dépendances (Node déjà présent)
  provisioner "shell" {
    only = ["docker.node"]
    inline = [
      "cd /app && npm install",
      # Démarrer l'API en arrière-plan pour le healthcheck
      "node /app/src/index.js &",
      "sleep 3",
      "curl -f http://localhost:3000/auth/secret-mysecretphrase && echo 'Healthcheck Docker OK.'",
    ]
  }

  # Tagger l'image Docker
  post-processor "docker-tag" {
    repository = "ci-cd-api"
    tags       = ["latest"]
    only       = ["docker.node"]
  }

  # Générer le manifest pour récupérer l'AMI ID
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    only       = ["amazon-ebs.ubuntu"]
  }
}
