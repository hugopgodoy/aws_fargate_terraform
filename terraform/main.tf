# group polices:
# AmazonEC2ContainerRegistryPowerUser (acesso EC2) ou PowerUserAccess (acesso local)

variable "availability_zone_east_b" {
  type    = string
  default = "us-east-1b"
}

variable "availability_zone_east_a" {
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

  enable_dns_hostnames             = true

  tags = {
    "project" = "poc",
    "Name"    = "poc-vpc-01"
  }
}


resource "aws_route_table" "poc_router_table_private" {
  vpc_id       = aws_vpc.poc_vpc_01.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.poc_natgateway.id
  }

  depends_on     = [aws_nat_gateway.poc_natgateway]

  tags = {
    "project" = "poc",
    "Name"    = "poc-router-table-nat"
  }
}

resource "aws_route_table" "poc_router_table_public" {
  vpc_id       = aws_vpc.poc_vpc_01.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.poc_internetgateway.id
  }

  tags = {
    "project" = "poc",
    "Name"    = "poc-router-table-internetgateway"
  }

  depends_on = [aws_internet_gateway.poc_internetgateway]
}

resource "aws_subnet" "poc_subnet_public_01" {
  vpc_id                  = aws_vpc.poc_vpc_01.id
  availability_zone       = var.availability_zone_east_a
  cidr_block              = "10.0.0.0/24"

  map_public_ip_on_launch = true

  tags = {
    "project" = "poc",
    "Name"    = "poc-subnet-public-01"
  }
}

resource "aws_subnet" "poc_subnet_private_01" {
  vpc_id                  = aws_vpc.poc_vpc_01.id
  availability_zone       = var.availability_zone_east_a
  cidr_block              = "10.0.1.0/24"

  tags = {
    "project" = "poc",
    "Name"    = "poc-subnet-private-01"
  }
}

resource "aws_subnet" "poc_subnet_private_02" {
  vpc_id                  = aws_vpc.poc_vpc_01.id
  availability_zone       = var.availability_zone_east_b
  cidr_block              = "10.0.2.0/24"

  tags = {
    "project" = "poc",
    "Name"    = "poc-subnet-private-02"
  }
}

resource "aws_security_group" "allow_db_access" {
  name        = "allow-db-access"
  description = "Allow db inbound traffic"
  vpc_id      = aws_vpc.poc_vpc_01.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    
    cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    from_port    = 0
    to_port      = 0
    protocol     = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  tags = {
    "project" = "Name",
    "Name"    = "allow_db_access"
  }
}


resource "aws_security_group" "allow_net_access" {
  name        = "allow-net-access"
  description = "Allow internet inbound traffic"
  vpc_id      = aws_vpc.poc_vpc_01.id

  ingress {
    from_port    = 80
    to_port      = 80
    protocol     = "tcp"
    
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port    = 443
    to_port      = 443
    protocol     = "tcp"
    
    cidr_blocks  = ["0.0.0.0/0"]
  }

  ingress {
    from_port    = 8080
    to_port      = 8080
    protocol     = "tcp"
    
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port    = 0
    to_port      = 0
    protocol     = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  tags = {
    "project" = "poc"
    "Name"    = "allow_net_access"
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
    
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    "project" = "poc",
    "Name"    = "allow_ssh_access"
  }
}

resource "aws_instance" "poc_ec2_01" {
  ami                         = "ami-04b9e92b5572fa0d1" # us-east-1
  instance_type               = "t2.micro"

  vpc_security_group_ids      = [aws_security_group.allow_net_access.id, aws_security_group.allow_ssh_access.id, aws_security_group.allow_db_access.id]

  subnet_id                   = aws_subnet.poc_subnet_public_01.id

  key_name                    = "poc-keypair-01"
  associate_public_ip_address = true


  provisioner "local-exec" {
    command = "echo ${aws_instance.poc_ec2_01.public_ip} > ip_address.txt"
  }

  tags = {
    "project" = "poc",
    "Name"    = "poc_ec2_01"
  }

  depends_on = [aws_internet_gateway.poc_internetgateway]  
}

resource "aws_key_pair" "poc_keypair_01" {
  key_name   = "poc-keypair-01"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_internet_gateway" "poc_internetgateway" {
  vpc_id = aws_vpc.poc_vpc_01.id

  tags = {
    "project" = "poc",
    "Name"    = "poc-iternetgateway"
  }
}

resource "aws_eip" "poc_eip_01" {
  vpc = true
  
  tags = {
    "project" = "poc",
    "Name"    = "poc-eip-01"
  }

  depends_on = [aws_internet_gateway.poc_internetgateway]
}

resource "aws_nat_gateway" "poc_natgateway" {
  allocation_id = aws_eip.poc_eip_01.id
  subnet_id     = aws_subnet.poc_subnet_public_01.id

  tags = {
    "project" = "poc",
    "Name"    = "poc-natgateway"
  }
}


resource "aws_db_subnet_group" "poc_dbsubnetgroup_01" {
  name       = "poc-dbsubnetgroup-01"
  subnet_ids = [aws_subnet.poc_subnet_private_01.id, aws_subnet.poc_subnet_private_02.id]

  tags = {
    "project" = "poc",
    "Name"    = "poc-dbsubnetgroup-01"
  }
}

resource "aws_route_table_association" "poc_router_subnet_public_01" {
  subnet_id      = aws_subnet.poc_subnet_public_01.id
  route_table_id = aws_route_table.poc_router_table_public.id
}

resource "aws_route_table_association" "poc_router_subnet_private_01" {
  subnet_id      = aws_subnet.poc_subnet_private_01.id
  route_table_id = aws_route_table.poc_router_table_private.id
}

resource "aws_route_table_association" "poc_router_subnet_private_02" {
  subnet_id      = aws_subnet.poc_subnet_private_02.id
  route_table_id = aws_route_table.poc_router_table_private.id
}


resource "aws_db_instance" "poc_db_01" {
  identifier                = "poc-db-01"
  availability_zone         = var.availability_zone_east_a
  engine                    = "postgres"
  engine_version            = "11.5"
  instance_class            = "db.t2.micro"
  allocated_storage         = 20

  name                      = "poc_demo"
  username                  = "poc_user"
  password                  = "ci&t2020"
  port                      = "5432"

  publicly_accessible       = true # fechar para nao acesso externo

  storage_encrypted         = false
  deletion_protection       = false

  # final_snapshot_identifier = true
  skip_final_snapshot       = true

  vpc_security_group_ids    = [aws_security_group.allow_db_access.id]
  db_subnet_group_name      = aws_db_subnet_group.poc_dbsubnetgroup_01.name

  tags = {
    "project"     = "poc",
    "Name"        = "poc-db-01",
    "environment" = "demo"
  }
}