region = "eu-west-2"

#RDS

rds_instance_identifier = "terraform-mysql"
database_name = "terraform_test_db"
database_user = "terraform"

#Web App

s3_bucket_name = "springboot-s3-example"

# Server instances

amis = {
  "eu-west-2" = "ami-ebd02392"
}

instance_type = "t2.micro"
autoscaling_group_min_size = 3
autoscaling_group_max_size = 5