output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_wan_subnet_id" {
  value = aws_subnet.public_wan.id
}

output "private_k8s_subnet_id" {
  value = aws_subnet.private_k8s.id
}

output "mgmt_subnet_id" {
  value = aws_subnet.mgmt.id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}
