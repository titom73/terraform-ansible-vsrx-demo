# Terraform and Ansible integration to build AWS topology

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Introduction](#introduction)
  - [Detailled Topology description](#detailled-topology-description)
- [Requirements](#requirements)
- [Repository structure](#repository-structure)
- [Configuration](#configuration)
  - [AWS Configuration (Required)](#aws-configuration-required)
  - [Configure SSH Access (Optional)](#configure-ssh-access-optional)
  - [Update Network information (Optional)](#update-network-information-optional)
- [Ansible provisionning](#ansible-provisionning)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Introduction

This repository provides a `terraform` stack to build a short devops demo running an Ubuntu server and 2 VSRXs in a single VPC.

- Devops Machine: [Ubuntu 16.04LTS](https://aws.amazon.com/marketplace/pp/B01JBL2M0O)
- VSRX running [BYOL](https://aws.amazon.com/marketplace/pp/B01LYWCGDX)

A subnet is configured to support management access from outside and from the devops VM. Besides that, each VSRX is connected to an untrust network and a deidcated trust network per device.

- Management subnet: `10.0.255.0/24`
- Untrust subnet: `10.0.10.0/24`
- Trust network: `10.0.{1,2}.0/24`

Short story to run the demo:

```shell
terraform init
terraform apply
```

But before that, it is important to go through the configuration steps

Ansible playbook is called by a call to `local-exec`. Because VSRX take time to boot, it is required to put a sleep timer of 10 minutes before starting ansible stuff.

### Detailled Topology description

Tpology comes with following elements:

- 1 VPC with a full CIDR set to `10.0.0.0/16`.
- 1 Management network set to 10.0.255.0/24. Public IPs are allocated to private resources part of this subnet.
- 1 Untrust subnet: `10.0.10.0/24`.
- 2 Trust networks: `10.0.{1,2}.0/24`.
- 1 RT with management and untrust subnets attached to it.
- 1 Internet Gateway.
- 1 NAT Gateway.
- 1 Ubuntu 16.04 LTS Instance.
- 2 VSRX instances.
- 1 SG attached to all management interfaces.

__Ubuntu instance:__
- Management IP: `10.0.255.10`
- Login information: 
	- username: `ubuntu`
	- password: NO
	- Key file: files part of [`provisionning/`](provisionning/)

__VSRX #1:__
- Management IP (fxp0): `10.0.255.21`
	- 1 `EIP` configured and attached to this `network_interface` 
- Login information: 
	- username: `root`
	- password: NO
	- Key file: files part of [`provisionning/`](provisionning/)
- Untrust network: `ge-0/0/0` (Not configured)
- Trust network: `ge-0/0/1` (Not configured)

__VSRX #2:__
- Management IP (fxp0): `10.0.255.22`
	- 1 `EIP` configured and attached to this `network_interface` 
- Login information: 
	- username: `root`
	- password: NO
	- Key file: files part of [`provisionning/`](provisionning/)
- Untrust network: `ge-0/0/0` (Not configured)
- Trust network: `ge-0/0/1` (Not configured)

__Security Group (devops.days.jnpr.access.any)__
- Allow JUNIPER VPN IPs and VPC Full CIDR for `22/tcp`
- Allow JUNIPER VPN IPs and VPC Full CIDR for `830/tcp`
- Allow JUNIPER VPN IPs and VPC Full CIDR for `ICMP`


## Requirements

To run this demo, you must complete these requirements:

- [`terraform`](https://www.terraform.io): At least version `0.11.4`
- [`ansible`](https://www.ansible.com): At least version `2.5` since we are using `network_cli` connection
- Python libraries: `botocore`, `boto3`, `junos-eznc`, `awscli`

If `python-pip` is part of your system, you can install ansible and python modules with the following command:

```shell
pip install --upgrade -r requirements.txt
```

## Repository structure

Repository comes with a scalable structure to support terraform deployment approach: `Project / Environment / Region / Stack`. Besides that, a location has been dedicated to store all the ansible provisionning content under `provisionning`. And a place to store all global variables related to all projects is available at [`variables.global`](variables.global)

Finally, local modules used in this demo are stored under `modules` folder.

```
├── devops.days
│   ├── README.md
│   ├── dev
│   │   └── eu-west-2
│   │       ├── stack01
│   │       │   ├── ansible.cfg
│   │       │   ├── main.tf
│   │       │   ├── networks.tf
│   │       │   ├── security.tf
│   │       │   ├── variables.global.tf
│   │       │   ├── variables.region.tf
│   │       │   ├── variables.stack.tf
│   │       │   ├── variables_override.tf
│   │       │   ├── vars.local.tf
│   │       │   ├── vsrx1.tf
│   │       │   └── vsrx2.tf
│   │       └── vars.region.tf
│   └── vars.stack.tf
├── modules
│   └── secure.vpc
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── provisioning
│   ├── jdevops.days
│   │   ├── ansible.cfg
│   │   ├── group_vars
│   │   │   ├── all.yml
│   │   │   ├── tag_Os_junos.yml
│   │   │   └── tag_Os_ubuntu.yml
│   │   ├── inventory
│   │   │   ├── ec2.ini
│   │   │   ├── ec2.py
│   │   │   └── vars.ini
│   │   ├── pb.vsrx.configure.yml
│   │   └── terraform.tfstate
│   ├── terraform-provision
│   └── terraform-provision.pub
├── requirements.txt
└── variables.global
    └── vars.global.tf
```

Some variables files are defined at different stack level for different visibility:
- Global variables: [`variables.global/vars.global.tf`](variables.global/vars.global.tf) list all variables share among all potential projects.
- Project variables: [`project_name/vars.stack.tf`](devops.days/vars.stack.tf) centralized all variables related to the project such as `CIDR`, `AMI`, ...
- Region variables: [`project_name/environment/region/vars.region.tf`](devops.days/dev/eu-west-2/vars.region.tf) contains variables related to a specific region
- Local variables: [`project_name/environment/region/stack`](devops.days/dev/eu-west-2/stack01/vars.local.tf) where local variables are configured.

To load all these variables during `terraform` execution, symbolic links have been created like this: 

```
ln -s ../../../var_file.tf vars.file.tf
```

In the stack folder, you have different files containing dedicated scope:

- [`main.tf`](devops.days/dev/eu-west-2/stack01/main.tf): file with module usage and jdevops declaration
- [`networks.tf`](devops.days/dev/eu-west-2/stack01/networks.tf): configuration of all the network part
- [`security.tf`](devops.days/dev/eu-west-2/stack01/security.tf): SG configuration
- [`vsrx1.tf`](devops.days/dev/eu-west-2/stack01/vsrx1.tf) and [`vsrx2.tf`](devops.days/dev/eu-west-2/stack01/vsrx2.tf): VSRX configuration

## Configuration

### AWS Configuration (Required)

Terraform is configured to use AWSCLI configuration to authenticate against AWS. So the first step is to create AWSCLI configuration. If it is the first time you are using it, follow the step below:

```shell
aws configure
AWS Access Key ID [None]: <PUT YOUR ACCESS KEY HERE>
AWS Secret Access Key [None]: <PUT YOUR SECRET KEY HERE>
Default region name [None]: eu-west-2    <---- Change according your location
Default output format [None]: json
```

If you already have another token, edit awscli's configuration files to add a new profile:

```
~/.aws/config

[juniper]
region=eu-west-2
output=json
```

```
~/.aws/credentials

juniper]
aws_access_key_id=<PUT YOUR ACCESS KEY HERE>
aws_secret_access_key=<PUT YOUR SECRET KEY HERE>
```

Then, we have to instruct terraform to use thi new profile:

```
sed -i.bak 's/default = \"default\"/default = "juniper"/g' variables.global/vars.global.tf
```

### Configure SSH Access (Optional)

A default private/public ssh-key is part of the repository to run the demo, but you can also create your own key pair like this:

```
ssh-keygen -t rsa -C "terraform.demo@juniper.net" -f provisionning/terraform-provision
```

Terraform will configure this key in AWS and then you will be able to use it to connect to devices. It is also used by `ansible` to connect and provision instances.

### Update Network information (Optional)

Some values are used by default and should not impact you as everything is configured in a dedicated VPC. If you want to update this information, you can edit [variables file](devops.days/vars.stack.tf) in the stack:

```
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
```

## Ansible provisionning

For every VSRX device part of the setup, a `local-exec` is executed to start ansible and to provision device. Inventory is managed by 2 files: `ec2.py` and `ec2.ini` provided by ansible to pull out information from AWS.

In order to make host filtering, instances are created with some tags by terraform:
- _Name_: give a name to the instance
- _Os_: Operating system. Easy to apply juniper tasks to only junos devices.
- _Stack_: easier as well to apply content only on our project.

All variables related to group or hosts are put on `group_vars` and `host_vars` folders and not part of inventory file. Then, for junos point of view, we have created a [`group_vars/tag_Os_junos.yml`](provisionning/jdevops.days/group_vars/tag_Os_junos.yml) file with the following content:

```yaml
---
  ansible_ssh_private_key_file: "/Users/$HOME/<PATH_TO_YOUR_LOCAL_COPY>/terraform.juniper/provisioning/terraform-provision"
  ansible_ssh_user: "root"
  private_key_file: "{{ansible_ssh_private_key_file}}"
  remote_user: "{{ansible_ssh_user}}"
  ansible_paramiko_host_key_checking: false
  ansible_network_os: "junos"

  credential:
    host: "{{ ansible_host }}"
    port: "830"
    username: "{{ansible_ssh_user}}"
    ssh_keyfile: "{{private_key_file}}"
```

> You have to update path to your local version in [the file](provisionning/jdevops.days/group_vars/tag_Os_junos.yml): <PATH_TO_YOUR_LOCAL_COPY>

Based on that, we have the following [simple playbook](provisionning/jdevops.days/pb.vsrx.configure.yml) to push configuration by using [`Juniper.junos`](https://github.com/Juniper/ansible-junos-stdlib) by using a netconf call:

```yaml
---
- name: Provision vsrx01
  hosts: tag_Name_vsrx1_jdevops_day
  connection: local
  gather_facts: no
  roles:
    - Juniper.junos
  vars:
    # Only for MacOS https://github.com/Juniper/ansible-junos-stdlib/issues/245
    ansible_python_interpreter: /usr/local/bin/python
  tasks:
    - name: Push configuration lines
      juniper_junos_config:
        load: 'merge'
        lines:
          - 'set system host-name vsrx01'
[...]
```

Because provisionner is executed on any new VSRX, we are limiting execution to host IP:

```shell
ansible-playbook ../../../../provisioning/jdevops.days/pb.vsrx.configure.yml -i ../../../../provisioning/jdevops.days/inventory --limit ${aws_instance.vsrx2.public_ip}
```