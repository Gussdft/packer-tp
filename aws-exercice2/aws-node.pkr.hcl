packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "node_version" {
  type    = string
  default = "20.0.0"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.node_version))
    error_message = "La variable node_version doit respecter le format x.y.z (ex: 18.0.0)."
  }
}

variable "env" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "production"], var.env)
    error_message = "La variable env doit être l'une des valeurs suivantes : dev, staging, production."
  }
}

locals {
  timestamp            = regex_replace(timestamp(), "[- TZ:]", "")
  node_install_version = var.env == "production" ? "lts/*" : var.node_version
}

source "amazon-ebs" "ubuntu" {
  ami_name               = "learn-packer-node-${var.env}-${local.timestamp}"
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
  name    = "learn-packer-node"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    environment_vars = [
      "NODE_VERSION=${local.node_install_version}",
      "ENV=${var.env}",
    ]
    inline = [
      # Installer nvm
      "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash",
      # Sourcer nvm et installer la version Node
      "export NVM_DIR=\"$HOME/.nvm\" && [ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\" && nvm install $NODE_VERSION && nvm use $NODE_VERSION && node --version",
      "echo \"Build env: $ENV - Node version: $NODE_VERSION\"",
    ]
  }
}
