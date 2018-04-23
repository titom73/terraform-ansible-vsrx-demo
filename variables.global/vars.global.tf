data "aws_availability_zones" "available" {}

# AWS Provider using aws-cli parameters
variable "profile" {
  type = "string"
  default = "juniper"
}
provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
  version = "~> 1.14"
}

# SSH Key to configure on remote instances
variable "global_key_name" {
  default = "tgr-terraform-provision"
  description = "Personal SSH Key to use to connect to VMs"
}

# Dict of AMI for Junos Devops Instance
variable "AmiDevopsJuniper" {
  type = "map"
  default = {
    us-east-2 = "ami-4added2f"
    eu-west-2 = "ami-ebf91a8c"
  }
  description = "AMI to deploy a Juniper Devops server"
}

resource "aws_key_pair" "terraform-provision" {
  key_name   = "tgr-terraform-provision"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC29jobziW5Bln6C5RSnOwNx6+CwT8VdBGkzESeKqwqZIu6XbF8jBmyBmas18qLNNH3O3bTzSITzA3T5ws8vm8PpfxoMHcqyacgxzvBiMUPxA5A9WBHDSMfvxc4k8HFEL1ephexhcCuMbB2xPbkJkufrCXlUFg2hngDZLItCngokH8RqyR6s7+3ZNowgN+sPL/rkfTpKyasSHEa1heSLtJK0JlSC6JvfYu397XN/Ndfik+TXpIiCB1jTiIbypUAHtqhltMoJ/35z23IdQIJpCPjoiGuUiLgvjFrA272oaapN6EVY6Jy0lxvyNEFsQCXVY14Ps6dBGLGjQl5maS0ES6x tgrimonet+terraform@juniper.net"
}