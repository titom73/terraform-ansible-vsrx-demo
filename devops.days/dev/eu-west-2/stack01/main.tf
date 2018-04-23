### Build basic VPC with :
#     - 1 Security Group to allow ANY from Juniper Public IPs
#     - 1 Subnet with public IP allocation
#     - Routing table and IGW / NAT GW
module "user_vpc" {
  source = "../../../../modules/secure.vpc"
  name = "${var.stack}"
  region = "${var.region}"
  fullcidr = "${var.vpc_fullcidr}"
  cidr_public_net = "${var.cidr_management_net}"
}


### Devops Instance with 1 network Interface:
#      - Interface 1: eth0 --> Public IP acting as management network as well.
resource "aws_instance" "jdevops" {
  ami           = "${lookup(var.AmiDevopsJuniper, var.region)}"
  instance_type = "${lookup(var.InstanceSize, var.branch)}"
  key_name = "${aws_key_pair.terraform-provision.key_name}"
  associate_public_ip_address = "true"
  subnet_id = "${module.user_vpc.net_public_id}"
  vpc_security_group_ids = ["${module.user_vpc.sg_juniper_access_id}"]
  tags {
        Name = "devops",
        Os = "ubuntu",
        stack = "${var.stack}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf $HOME/.ansible",
    ]
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file("/Users/tgrimonet/Scripting/terraform.juniper/provisioning/tgr-terraform-provision")}"
    }
  }
}


########  Complex Use Case with 1 Public and 1 private management ############

# ### Create Devops interfaces to public and management subnets
# resource "aws_network_interface" "devops_mgt" {
#   subnet_id = "${aws_subnet.net_management.id}"
#   tags {
#     Name = "management_interface"
#   }
# }
# resource "aws_network_interface" "devops_public" {
#   subnet_id = "${module.user_vpc.net_public_id}"
#   security_groups = ["${module.user_vpc.sg_juniper_access_id}"]
#   tags {
#     Name = "trust1_interface"
#   }
# }

# ### aws ec2 allocate-address for devops VM
# resource "aws_eip" "devops_public" {
#   vpc     = true
#   network_interface = "${aws_network_interface.devops_public.id}"
# }

# ### Devops Instance with 2 different Interfaces:
# #      - Interface 1: eth0 --> public subnet with EIP mapping
# #      - Interface 2: eth1 --> management subnet with IP provisionned (Must be manually configured)
# resource "aws_instance" "jdevops" {
#   ami           = "${lookup(var.AmiDevopsCentos, var.region)}"
#   instance_type = "${lookup(var.InstanceSize, var.branch)}"
#   key_name = "${var.global_key_name}"
#   network_interface {
#      network_interface_id = "${aws_network_interface.devops_public.id}"
#      device_index = 0
#      private_ips     = ["10.0.0.10"]
#   }
#   network_interface {
#      network_interface_id = "${aws_network_interface.devops_mgt.id}"
#      device_index = 1
#      private_ips     = ["10.0.255.10"]
#   }
#   tags {
#         Name = "Devops #1",
#         Os = "centos",
#         stack = "${var.stack}"
#   }
# }