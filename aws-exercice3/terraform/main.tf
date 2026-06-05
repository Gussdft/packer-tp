terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Security group autorisant HTTP (80) et SSH (22)
resource "aws_security_group" "nginx_sg" {
  name        = "nginx-packer-sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instance EC2 depuis l'AMI Packer
resource "aws_instance" "nginx" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  tags = {
    Name = "nginx-packer-instance"
  }
}

output "public_ip" {
  value       = aws_instance.nginx.public_ip
  description = "IP publique de l'instance EC2"
}

output "url" {
  value       = "http://${aws_instance.nginx.public_ip}"
  description = "URL pour accéder au serveur Nginx"
}
