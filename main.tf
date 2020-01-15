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
  region = "us-east-1"
}

resource "aws_vpc" "poc-vpc-01" {
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

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.poc-vpc-01.id
}

# variable "vpc_id" {}

data "aws_vpc" "selected" {
  id = aws_vpc.poc-vpc-01.id
}

resource "aws_subnet" "poc-subnet-public-01" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = var.availability_zone_east
  cidr_block        = cidrsubnet(data.aws_vpc.selected.cidr_block, 4, 1)

  tags = {
    "Name" = "poc-subnet-public-01"
  }
}

resource "aws_security_group" "allow_db_access" {
  name        = "allow_db_access"
  description = "Allow postgres inbound traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    # cidr_blocks = # add your IP address here
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    # prefix_list_ids = ["pl-12c4e678"]
  }

  tags = {
    "Name" = "allow db pg"
  }
}


resource "aws_security_group" "allow_net_access" {
  name        = "allow_net_access"
  description = "Allow internet inbound traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    # cidr_blocks = # add your IP address here
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    # cidr_blocks = # add your IP address here
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    # prefix_list_ids = ["pl-12c4e678"]
  }

  tags = {
    "Name" = "allow net"
  }
}

resource "aws_security_group" "allow_ssh_access" {
  name        = "allow_ssh_access"
  description = "Allow ssh inbound traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    # cidr_blocks = # add your IP address here
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    # prefix_list_ids = ["pl-12c4e678"]
  }

  tags = {
    "Name" = "allow ssh"
  }
}



resource "aws_instance" "poc-ec2-01" {
  ami             = "ami-b374d5a5" # us-east-1
  instance_type   = "t2.micro"

  vpc_security_group_ids = [aws_security_group.allow_net_access.id, aws_security_group.allow_ssh_access.id, aws_security_group.allow_db_access.id]

  subnet_id = aws_subnet.poc-subnet-public-01.id

  provisioner "local-exec" {
    command = "echo ${aws_instance.poc-ec2-01.public_ip} > ip_address.txt"
  }  
}


# resource "aws_network_interface" "multi-ip" {
#   subnet_id   = aws_subnet.poc-subnet-public-01.id
#   # private_ips = ["10.0.0.10", "10.0.0.11"]
# }

resource "aws_eip" "one" {
  vpc                       = true
  # network_interface         = aws_network_interface.multi-ip.id
  instance                  = aws_instance.poc-ec2-01.id
  depends_on                = [aws_internet_gateway.gw]
  # associate_with_private_ip = "10.0.0.10"
}










# resource "aws_db_instance" "poc-db-01" {
#   identifier                = "poc-db-01"
#   availability_zone         = var.availability_zone_east
#   engine                    = "postgres"
#   engine_version            = "11.5"
#   instance_class            = "db.t2.micro"
#   allocated_storage         = 20

#   name                      = "poc_demo"
#   username                  = "poc_user"
#   password                  = "ci&t2020"
#   port                      = "5432"

#   storage_encrypted         = false
#   deletion_protection       = false

#   # final_snapshot_identifier = true
#   skip_final_snapshot       = true

#   vpc_security_group_ids    = [aws_security_group.allow_db_access.id]
#   # vpc ????
  # db_subnet_group_name      = data.aws_subnet.selected.id # ????????

#   tags = {
#     Owner       = "user"
#     Environment = "demo"
#   }
# }