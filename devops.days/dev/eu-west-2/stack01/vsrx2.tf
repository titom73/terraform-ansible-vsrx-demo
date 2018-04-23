## VSRX Configuration

### aws ec2 allocate-address for devops VM
resource "aws_eip" "vsrx2_public" {
  vpc     = true
  network_interface = "${aws_network_interface.vsrx2_fxp0.id}"
}

resource "aws_network_interface" "vsrx2_fxp0" {
  subnet_id = "${module.user_vpc.net_public_id}"
  private_ips = ["10.0.255.22"]
  security_groups = ["${module.user_vpc.sg_juniper_access_id}"]
  tags {
    Name = "management_interface"
  }
}

# ### aws ec2 allocate-address for devops VM
# resource "aws_eip" "devops_public" {
#   vpc     = true
#   network_interface = "${aws_network_interface.devops_public.id}"
# }

# resource "aws_network_interface" "vsrx_trust1" {
#   subnet_id = "${var.aws_subnet.net_trust1.id}"
#   tags {
#     Name = "trust1_interface"
#   }
# }

resource "aws_network_interface" "vsrx2_untrust" {
  subnet_id = "${aws_subnet.net_untrust.id}"
  security_groups = ["${aws_security_group.allow_any.id}"]
  tags {
    Name = "untrust_interface"
  }
}


resource "aws_instance" "vsrx2" {
  ami = "${lookup(var.AmiVsrxByol, var.region)}"
  instance_type = "${lookup(var.VsrxInstanceSize, var.branch)}"
  disable_api_termination = false
  key_name = "${aws_key_pair.terraform-provision.key_name}"
  network_interface {
     device_index = 0
     network_interface_id = "${aws_network_interface.vsrx2_fxp0.id}"
  }
  network_interface {
    device_index = 1
    network_interface_id = "${aws_network_interface.vsrx2_untrust.id}"
  }
  tags {
    Name = "vsrx2-${var.stack}",
    stack = "${var.stack}",
    Os = "junos"
  }
  provisioner "local-exec" {
    command = "sleep 600 ; ansible-playbook ../../../../provisioning/jdevops.days/pb.vsrx.configure.yml -i ../../../../provisioning/jdevops.days/inventory --limit ${aws_instance.vsrx2.public_ip}"
  }
}