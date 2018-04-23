# Terraform stack to build Automation Training stack

## Introduction

This terraform stack provides a complete topology to run basic automation training. Each stack will deploy the following topology:

- 1 dedicated VPC
- 1 Linux DevOps Instance with a public IP
- 2 VSRXs

All instances are attached to the management network and only devops VM has a public IP to connect.


## IP Addresses

__Management network:__

- Devops VM: 10.0.255.10
- VSRX 1: 10.0.255.21
- VSRX 2: 10.0.255.22

## Configuration

__Authentication__

In order to play with this terraform stack, you have to configure your AWS secret like this:

```
~/.aws/config

[juniper]
region=us-east-2
output=table
```

```
~/.aws/credentials

[juniper]
aws_access_key_id=<PUT YOUR ACCESS KEY HERE>
aws_secret_access_key=<PUT YOUR SECRET KEY HERE>
```

All the authentication part is defined in file [`variables.global/vars.global.tf`](https://git.juniper.net/tgrimonet/terraform.juniper.stacks/blob/master/variables.global/vars.global.tf)

```
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
  default = "tgrimonet-ssh-key"
  description = "Personal SSH Key to use to connect to VMs"
}

```

__Customize project__

In the file [`vars.stack.tf`](https://git.juniper.net/tgrimonet/terraform.juniper.stacks/blob/master/devops.days/vars.stack.tf) you can edit following information:

- CIDR block of your VPC
- CIDR block of your management / public subnet
- CIDR of any network used in the project.
- Size of both AMIs: devops and VSRX and per branch approach (dev/staging/production)
- AMI ids of both devops and VSRX images per region

__Use a specific region:__

Go to `dev/` and copy `eu-west-2` to a new folder with the name of your region. Then edit file in `dev/your-region/vars.region.tf` and replace `eu-west-2` by your region:

```
# Region where to deploy stack
variable "region" {
  default = "us-east-2"
}
```
