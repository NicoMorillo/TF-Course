provider "aws" {
  region = "eu-west-2"
}

locals {
  extra_tag = "extra-tag"
}

resource "aws_instance" "instance" {
  ami = var.ami
  instance_type = var.intance_type

  tags = var.instance_type
    Name = var.instance_name
    ExtraTag = local.extra_tag
}

resource "aws_db_instance" "db_instance" {
    allocated_storage = 20
    storage_type = "gp2"
    engine = "postgres"
    engine_version = "12.4"
    instance_class = "db.t2.micro"
    name = "mydb"
    username = var.db_user
    password = var.db_pass
   skip_final_snapshot = true
}