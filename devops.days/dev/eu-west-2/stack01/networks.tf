### Create 4 subnets with only private IP addresses
resource "aws_subnet" "net_trust1" {
  vpc_id = "${module.user_vpc.vpcid}"
  cidr_block = "${var.cidr_trust_net1}"
  map_public_ip_on_launch = "True"
  tags {
        Name = "trust net ${var.stack}"
  }
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}
resource "aws_subnet" "net_trust2" {
  vpc_id = "${module.user_vpc.vpcid}"
  cidr_block = "${var.cidr_trust_net2}"
  map_public_ip_on_launch = "True"
  tags {
        Name = "trust net ${var.stack}"
  }
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}
resource "aws_subnet" "net_untrust" {
  vpc_id = "${module.user_vpc.vpcid}"
  cidr_block = "${var.cidr_untrust_net}"
  map_public_ip_on_launch = "True"
  tags {
        Name = "trust net ${var.stack}"
  }
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

### Attach subnets to RT created in module
# resource "aws_route_table_association" "net_trust1" {
#     subnet_id = "${aws_subnet.net_trust1.id}"
#     route_table_id = "${module.user_vpc.rtid}"
# }
# resource "aws_route_table_association" "net_untrust" {
#     subnet_id = "${aws_subnet.net_untrust.id}"
#     route_table_id = "${module.user_vpc.rtid}"
# }