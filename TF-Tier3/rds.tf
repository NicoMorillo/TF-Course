
#Create subnets in each AZ for RDS with address blocks within VPC

resource "aws_subnet" "rds" {
  count                   = "${length(data.aws_availability_zones.available.names)}" #length ... -> number of subnet for AZ possibles 
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.${length(data.aws_availability_zones.available.names) + count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  tags {
    Name = "rds-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

#Create subnet group with all RDS subnets

resource "aws_db_subnet_group" "default" {
  name = "${var.rds_instance_identifier}-subnet-group"
  description = "Terraform example RDS subnet group"
  subnets_ids = ["${aws_subnet.rds.*.id}"]
}

#Create a RDS securit group in the VPC which our database

resource "aws_security_group" "rds" {
    name = "terraform_rds_security_group"
    description = "Terraform example RDS MySQL server"
    vpc_id = "${aws_vpc.vpc.id}"

    #Keep the instance private by only allowing traffic from the web server

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = ["{aws_security_group.default.id}"]
    }

    #Allow all outbound traffic

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name = "terraform example rds security group"
    }
}

# Create a RDS MySQL db instance in VPC with our RDS subnet-g & sg

resource "aws_db_instance" "default" {
  identifier = "${var.rds_instance_identifier}"
  allocated_storage = 5
  engine = "mysql"
  engine_version = "5.6.35"
  instance_class = "db.t2.micro"
  db_name = "${var.database_name}"
  username = "${var.database_username}"
  password = "${var.database_password}"
  db_subnet_group_name = ["${aws_security_group.default.id}"]
  skip_final_snapshot = true
  final_snapshot_identifier = "Ignore"
}

# Manage MySQL confg with parameter group

resource "aws_db_parameter_group" "default" {
  name = "${var.rds_instance_identifier}-param-group"
  description = "Terraform example parameter group for mysql 15.6"
  family = "mysql15.6"
  parameter {
      name = "character_set_server"
      value = "utf8"
  }
}
