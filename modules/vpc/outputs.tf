output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}


output "elasticloadbalancer_dns_name" {
  value = aws_lb.elb.dns_name
}

output "elasticloadbalancer_arn" {
  value = aws_lb.elb.arn
}

output "availability_zones" {
  value = aws_subnet.private_subnets[*].availability_zone
}
