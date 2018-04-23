output "vpcname" {
  value = "${var.name}"
}

output "vpcid" {
  value  = "${aws_vpc.vpc_project.id}"
}

output "rtid" {
  value = "${aws_route_table.route_table.id}"
}

output "rt_association_id" {
  value = "${aws_route_table_association.net_public.id}"
}

output "net_public_id" {
  value = "${aws_subnet.net_public.id}"
}

output "sg_juniper_access_id" {
  value = "${aws_security_group.jnpr_access.id}"
}