#Should specify optional vs required (define variables)

variable "instance_name" {
    description = "Name of ec2 instance"
    type = string
}

variable "ami" {
    description = "Amazon machine image to use ec2 instance"
    type = string
    default = "ami-0dd555eb7eb3b7c82" #Linux
}

variable "instance_type" {
    description = "ec2 instance type"
    type = string
    default = "t2.micro"
}

variable "db_user" {
  description = "username for database"
  type = string
  default = "foo"
}

variable "db_pass" {
  description = "password for database"
  type = string
  sensitive = true
}