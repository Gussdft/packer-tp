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

resource "aws_security_group" "api_sg" {
  name        = "api-packer-sg"
  description = "Allow API port 3000 and SSH"

  ingress {
    from_port   = 3000
    to_port     = 3000
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

resource "aws_instance" "api" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.api_sg.id]

  tags = {
    Name = "ci-cd-api-instance"
  }
}

output "public_ip" {
  value = aws_instance.api.public_ip
}

output "url" {
  value = "http://${aws_instance.api.public_ip}:3000/auth/secret-mysecretphrase"
}
