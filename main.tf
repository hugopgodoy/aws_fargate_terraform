# group polices:
# AmazonEC2ContainerRegistryPowerUser (acesso EC2) ou PowerUserAccess (acesso local)

variable "availability_zone_west" {
  type    = string
  default = "us-west-1a"
}

variable "availability_zone_east" {
  type    = string
  default = "us-east-1a"
}

provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "main" {
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = "10.0.0.0/16"
  enable_dns_support               = true
  instance_tenancy                 = "default" # or 'dedicated'

  # arn                              = (known after apply)
  # default_network_acl_id           = (known after apply)
  # default_route_table_id           = (known after apply)
  # default_security_group_id        = (known after apply)
  # dhcp_options_id                  = (known after apply)
  # enable_classiclink               = (known after apply)
  # enable_classiclink_dns_support   = (known after apply)
  # enable_dns_hostnames             = (known after apply)
  # id                               = (known after apply)
  # ipv6_association_id              = (known after apply)
  # ipv6_cidr_block                  = (known after apply)
  # main_route_table_id              = (known after apply)
  # owner_id                         = (known after apply)

  tags = {
    "Name" = "poc-vpc-01"
  }
}

# variable "vpc_id" {}

data "aws_vpc" "selected" {
  id = aws_vpc.main.id
}

resource "aws_subnet" "example" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = var.availability_zone_west
  cidr_block        = cidrsubnet(data.aws_vpc.selected.cidr_block, 4, 1)

  tags = {
    "Name" = "poc-subnet-public-01"
  }
}

# resource "aws_db_instance" "default" {
#   identifier                = "sas-db-01"
#   availability_zone         = var.availability_zone_west
#   engine                    = "postgres"
#   engine_version            = "11.5"
#   instance_class            = "db.t2.micro"
#   allocated_storage         = 20

#   name                      = "pocdb"
#   username                  = "pocuser"
#   password                  = "ci&t2020"
#   port                      = "5432"

#   storage_encrypted         = false
#   deletion_protection       = false

#   final_snapshot_identifier = true

#   # vpc_security_group_ids = [data.aws_security_group.default.id]
#   # subnet_ids             = data.aws_subnet_ids.all.ids

#   tags = {
#     Owner       = "user"
#     Environment = "poc"
#   }
# }
