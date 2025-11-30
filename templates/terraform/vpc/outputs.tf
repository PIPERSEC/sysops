output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways"
  value       = module.vpc.natgw_ids
}

output "vpc_main_route_table_id" {
  description = "ID of VPC main route table"
  value       = module.vpc.vpc_main_route_table_id
}
