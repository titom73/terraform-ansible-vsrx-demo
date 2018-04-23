# Terraform and Ansible integration to build AWS topology

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

## Requirements

To run this demo, you must complete these requirements:

- [`terraform`](https://www.terraform.io): At least version `0.11.4`
- ['ansible'](https://www.ansible.com): At least version `2.5` since we are using `network_cli` connection
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
- Region variables: [`project_name/region/vars.region.tf`](devops.days/eu-west-2/vars.region.tf) contains variables related to a specific region
- Local variables: [`project_name/region/stack`](devops.days/eu-west-2/stack01/vars.local.tf) where local variables are configured.

To load all these variables during `terraform` execution, symbolic links have been created like this: 

```
ln -s ../../../var_file.tf vars.file.tf
```

In the stack folder, you have different files containing dedicated scope:

- [`main.tf`](devops.days/eu-west-2/stack01/main.tf): file with module usage and jdevops declaration
- [`networks.tf`](devops.days/eu-west-2/stack01/networks.tf): configuration of all the network part
- [`security.tf`](devops.days/eu-west-2/stack01/security.tf): SG configuration
- [`vsrx1.tf`](devops.days/eu-west-2/stack01/vsrx1.tf) and [`vsrx2.tf`](devops.days/eu-west-2/stack01/vsrx2.tf): VSRX configuration

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

Based on that, we have the following simple playbook to activate netconf and then get version by using a netconf call:

```yaml
---
- name: Connect to vSRXs
  hosts: tag_Os_junos
  connection: network_cli
  gather_facts: no
  tasks:
    - name: enable netconf service on port 830
      junos_netconf:
      listens_on: 830
      state: present

- name: Display version running (w/netconf)
  hosts: tag_Os_junos
  connection: local
  gather_facts: no
  tasks:
    - name: Get version
      junos_command:
        commands: show version
        provider: "{{ credential }}"
        display: text
      register: response
      
    - name: Display version
      debug:
        var: response
```
