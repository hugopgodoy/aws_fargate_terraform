variable "availability_zone_east" {
  type    = string
  default = "us-east-1a"
}

variable "availability_zone_west" {
  type    = string
  default = "us-west-1a"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "default" {
  identifier                = "sas-db-01"
  availability_zone         = var.availability_zone_east
  engine                    = "postgres"
  engine_version            = "11.5"
  instance_class            = "db.t2.micro"
  allocated_storage         = 20

  name                      = "pocdb"
  username                  = "pocuser"
  password                  = "ci&t2020"
  port                      = "5432"

  storage_encrypted         = false
  deletion_protection       = false

  final_snapshot_identifier = true

  # vpc_security_group_ids = [data.aws_security_group.default.id]
  # subnet_ids             = data.aws_subnet_ids.all.ids

  tags = {
    Owner       = "user"
    Environment = "poc"
  }
}
