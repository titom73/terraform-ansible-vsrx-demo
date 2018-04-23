resource "aws_security_group" "allow_any" {
  name        = "${var.stack}.access.any"
  description = "Allow all inbound traffic from Juniper networks"
  vpc_id      = "${module.user_vpc.vpcid}"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.stack}.access.any"
    stack = "${var.stack}"
  }
}