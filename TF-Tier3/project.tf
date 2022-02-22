provider "aws" {
    version = "~> 0.1"
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

#Creation VPC
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
      name = "terraform example vpc"
    }
}

#Creation internet gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    name = "terraform example internet gateway"
  }
}

# Route table, grant vpc internet access
resource "aws_route" "route" {
  route_table_id = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.gateway.id}"
}

#Create subnets in different availability zone
resource "aws_subnet" "main" {
    count = "${length(data.aws_availability_zones.available.names)}" #length ... -> number of subnet for AZ possibles 
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.${count.index}.0/24"
    map_public_ip_on_launch = true
    availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"

    tags = {
      name = "public-${element(data.aws_availability_zones.available.names, count.index)}"
    }
}

# Create security group in VPC
resource "aws_security_group" "default" {
  name        = "terraform security group"
  description = "Terraform example security group"
  vpc_id      = "${aws_vpc.vpc.id}"

  # Allow outbound internet access.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # First and second restrict inbount SSH and ICMP, and third rule restrict HTTPS ,just allow trafic from LB
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.allowed_cidr_blocks}"
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = "${var.allowed_cidr_blocks}"
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb.id}"]
  }

  tags {
    Name = "terraform example security group"
  }
}

#Create application load balancer security group
resource "aws_security_group" "alb" {
  name        = "terraform alb security group"
  description = "Terraform load balancer security group"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.allowed_cidr_blocks}"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.allowed_cidr_blocks}"
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "terraform-example-alb-security-group"
  }
}

#Create application load balancer
resource "aws_alb" "alb" {
  name            = "terraform-example-alb"
  security_groups = ["${aws_security_group.alb.id}"]
  subnets         = ["${aws_subnet.main.*.id}"]
  tags {
    Name = "terraform-example-alb"
  }
}

#Create target group for the ALB
resource "aws_alb_target_group" "group" {
  name     = "terraform example alb target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/login"
    port = 80
  }
}

#Create two new ALB -1
resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.group.arn}"
    type             = "forward"
  }
}

#Create second new ALB -2
resource "aws_alb_listener" "listener_https" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.certificate_arn}"
  default_action {
    target_group_arn = "${aws_alb_target_group.group.arn}"
    type             = "forward"
  }
}

#Define a record set in Route53 ALB
resource "aws_route53_record" "terraform" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "terraform.${var.route53_hosted_zone_name}"
  type    = "A"
  alias {
    name                   = "${aws_alb.alb.dns_name}"
    zone_id                = "${aws_alb.alb.zone_id}"
    evaluate_target_health = true
  }
}

