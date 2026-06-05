variable "docker_image" {
  type    = string
  default = "ubuntu:jammy"
}

variable "focal_image" {
  type    = string
  default = "ubuntu:focal"
}

variable "foo_content" {
  type    = string
  default = "hello world"
}

variable "tags_jammy" {
  type    = list(string)
  default = ["ubuntu-jammy", "packer-rocks"]
}

variable "tags_focal" {
  type    = list(string)
  default = ["ubuntu-focal", "packer-rocks"]
}
