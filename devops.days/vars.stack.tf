variable "stack" {
  type = "string"
  default = "jdevops.day"
}

variable "vpc_fullcidr" {
  type = "string"
  default = "10.0.0.0/16"
}

variable "cidr_trust_net1" {
  type = "string"
  default = "10.0.1.0/24"
}

variable "cidr_trust_net2" {
  type = "string"
  default = "10.0.2.0/24"
}

variable "cidr_untrust_net" {
  type = "string"
  default = "10.0.10.0/24"
}

variable "cidr_management_net" {
  type = "string"
  default = "10.0.255.0/24"
}

# Dict of instance sizes to use according the stack's branch
variable "InstanceSize" {
  type = "map"
  default = {
    dev     = "t2.micro"
    staging = "t2.large"
    prod    = "t2.xlarge"
  }
  description = "Size of instance to use per environment"
}

# Dict of instance sizes to use according the stack's branch
variable "VsrxInstanceSize" {
  type = "map"
  default = {
    dev     = "m4.xlarge"
    staging = "m4.xlarge"
    prod    = "m4.xlarge"
  }
  description = "Size of VSRX instance to use per environment"
}

# Dict of AMI to start VSRX BYOL
variable "AmiVsrxByol" {
  type = "map"
  default = {
    us-east-1 = "ami-4a09d335"
    us-east-2 = "ami-416a5924"
    us-west-1 = "ami-8f9182ef"
    us-west-2 = "ami-7dc4a705"
    ca-central-1 = "ami-90c342f4"
    eu-central-1 = "ami-f45c071f"
    eu-west-1 = "ami-d37155aa"
    eu-west-2 = "ami-5936d63e"
    ap-southeast-1 = "ami-dd0928a1"
    ap-southeast-2 = "ami-a2bf77c0" 
    ap-northeast-2 = "ami-faaa0494" 
    ap-northeast-1 = "ami-48c0dc34" 
    ap-south-1 = "ami-6f735400"
    sa-east-1 = "ami-a6b6e7ca"
  }
  description = "AMI to deploy a Juniper VSRX firewall"
}