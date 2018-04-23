variable "name" {
  type = "string"
}

variable "region" {
  type = "string"
}

variable "fullcidr" {
  type = "string"
  default = "10.0.0.0/16"
}

variable "cidr_public_net" {
  type = "string"
  default = "10.0.255.0/24"
}