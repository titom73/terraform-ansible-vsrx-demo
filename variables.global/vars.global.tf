data "aws_availability_zones" "available" {}

# AWS Provider using aws-cli parameters
variable "profile" {
  type = "string"
  default = "default"
}
provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
  version = "~> 1.14"
}

data "aws_ami" "amiUbuntu" {
  most_recent = true
  filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "terraform-provision" {
  key_name   = "terraform-provision"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC29jobziW5Bln6C5RSnOwNx6+CwT8VdBGkzESeKqwqZIu6XbF8jBmyBmas18qLNNH3O3bTzSITzA3T5ws8vm8PpfxoMHcqyacgxzvBiMUPxA5A9WBHDSMfvxc4k8HFEL1ephexhcCuMbB2xPbkJkufrCXlUFg2hngDZLItCngokH8RqyR6s7+3ZNowgN+sPL/rkfTpKyasSHEa1heSLtJK0JlSC6JvfYu397XN/Ndfik+TXpIiCB1jTiIbypUAHtqhltMoJ/35z23IdQIJpCPjoiGuUiLgvjFrA272oaapN6EVY6Jy0lxvyNEFsQCXVY14Ps6dBGLGjQl5maS0ES6x tgrimonet+terraform@juniper.net"
}