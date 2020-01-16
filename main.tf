# group polices:
# AmazonEC2ContainerRegistryPowerUser (acesso EC2) ou PowerUserAccess (acesso local)

variable "availability_zone_east_b" {
  type    = string
  default = "us-east-1b"
}

variable "availability_zone_east" {
  type    = string
  default = "us-east-1a"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "poc_vpc_01" {
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
  enable_dns_hostnames             = true
  # id                               = (known after apply)
  # ipv6_association_id              = (known after apply)
  # ipv6_cidr_block                  = (known after apply)
  # main_route_table_id              = (known after apply)
  # owner_id                         = (known after apply)

  tags = {
    "Name" = "poc-vpc-01"
  }
}

resource "aws_internet_gateway" "poc_gw" {
  vpc_id = aws_vpc.poc_vpc_01.id
}


resource "aws_route_table" "poc_router_table" {
  vpc_id = aws_vpc.poc_vpc_01.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.poc_gw.id
  }

  tags = {
    Name = "poc_router_table"
  }
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.poc_vpc_01.id
  route_table_id = aws_route_table.poc_router_table.id
}

resource "aws_subnet" "poc_subnet_east_01" {
  vpc_id            = aws_vpc.poc_vpc_01.id
  availability_zone = var.availability_zone_east
  # cidr_block        = cidrsubnet(aws_vpc.poc_vpc_01.cidr_block, 4, 1)
  cidr_block = "10.0.0.0/24"

  map_public_ip_on_launch = true

  tags = {
    "Name" = "poc-subnet-east-01"
  }
}

resource "aws_subnet" "poc_subnet_east_02" {
  vpc_id            = aws_vpc.poc_vpc_01.id
  availability_zone = var.availability_zone_east_b
  # cidr_block        = cidrsubnet(aws_vpc.poc_vpc_01.cidr_block, 4, 1)
  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = true

  tags = {
    "Name" = "poc-subnet-west-01"
  }
}

resource "aws_security_group" "allow_db_access" {
  name        = "allow-db-access"
  description = "Allow postgres inbound traffic"
  vpc_id      = aws_vpc.poc_vpc_01.id

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
  name        = "allow-net-access"
  description = "Allow internet inbound traffic"
  vpc_id      = aws_vpc.poc_vpc_01.id

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

  ingress {
    from_port   = 8080
    to_port     = 8080
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
  name        = "allow-ssh-access"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.poc_vpc_01.id

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

# resource "aws_network_interface" "multi_ip" {
#    subnet_id = aws_subnet.poc_subnet_east_01.id
#   # private_ips = ["10.0.0.10", "10.0.0.11"]
#   # vpc_id      = aws_vpc.poc_vpc_01.id
#   # availability_zone = 
# }


resource "aws_instance" "poc_ec2_01" {
  ami             = "ami-b374d5a5" # us-east-1
  instance_type   = "t2.micro"

  vpc_security_group_ids = [aws_security_group.allow_net_access.id, aws_security_group.allow_ssh_access.id, aws_security_group.allow_db_access.id]

  subnet_id = aws_subnet.poc_subnet_east_01.id

  key_name = "poc-keypair-01"
  associate_public_ip_address = true

  provisioner "local-exec" {
    command = "echo ${aws_instance.poc_ec2_01.public_ip} > ip_address.txt"
  }  
}

resource "aws_key_pair" "poc_keypair_01" {
  key_name   = "poc-keypair-01"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_eip" "poc_eip_01" {
  vpc                       = true
  # network_interface         = aws_network_interface.multi-ip.id # instancia OU interface
  instance                  = aws_instance.poc_ec2_01.id
  depends_on                = [aws_internet_gateway.poc_gw]
  # associate_with_private_ip = "10.0.0.10"
}


# resource "aws_db_subnet_group" "poc_dbsubnetgroup_01" {
#   name       = "poc-dbsubnetgroup-01"
#   subnet_ids = [aws_subnet.poc_subnet_east_01.id, aws_subnet.poc_subnet_east_02.id]

#   tags = {
#     Name = "POC RDS subnet group"
#   }
# }


# resource "aws_db_instance" "poc_db_01" {
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
#   db_subnet_group_name      = aws_db_subnet_group.poc_dbsubnetgroup_01.name

#   tags = {
#     Owner       = "user"
#     Environment = "demo"
#   }
# }