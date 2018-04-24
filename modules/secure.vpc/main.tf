# Declare the data source
data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc_project" {
  cidr_block = "${var.fullcidr}"
  #### this 2 true values are for use the internal vpc dns resolution
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "${var.name}"
  }
}

/* EXTERNAL NETWORK , IG, ROUTE TABLE */
resource "aws_internet_gateway" "gw" {
   vpc_id = "${aws_vpc.vpc_project.id}"
    tags {
        Name = "internet gw terraform generated"
    }
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.vpc_project.id}"
  tags {
      Name = "rt_${var.name}"
  }
  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }
}

resource "aws_eip" "nat_public" {
    vpc      = true
}

resource "aws_nat_gateway" "gw_public" {
    allocation_id = "${aws_eip.nat_public.id}"
    subnet_id = "${aws_subnet.net_public.id}"
    depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_subnet" "net_public" {
  vpc_id = "${aws_vpc.vpc_project.id}"
  cidr_block = "${var.cidr_public_net}"
  map_public_ip_on_launch = true
  tags {
        Name = "public net ${var.name}"
  }
 availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_route_table_association" "net_public" {
    subnet_id = "${aws_subnet.net_public.id}"
    route_table_id = "${aws_route_table.route_table.id}"
}

### Create default security group

resource "aws_security_group" "jnpr_access" {
  name        = "${var.name}.jnpr.access.any"
  description = "Allow all inbound traffic from Juniper networks"
  vpc_id      = "${aws_vpc.vpc_project.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["66.129.239.0/27", "66.129.239.64/27", "116.197.184.0/27", "116.197.184.64/27", "193.110.55.0/24", "${var.fullcidr}"]
  }
  ingress {
    from_port   = 830
    to_port     = 830
    protocol    = "tcp"
    cidr_blocks = ["66.129.239.0/27", "66.129.239.64/27", "116.197.184.0/27", "116.197.184.64/27", "193.110.55.0/24", "${var.fullcidr}"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["66.129.239.0/27", "66.129.239.64/27", "116.197.184.0/27", "116.197.184.64/27", "193.110.55.0/24", "${var.fullcidr}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}.jnpr.access.any"
    stack = "${var.name}"
  }
}