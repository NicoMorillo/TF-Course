Tier 3 AWS Terraform architecture.

** Set UP before Hosted Zone in Route 53

** Request a SSL certificate in AWS Certificate Manager
        Locate --> certificate_arn
        
** Set up a key pair
    # $ ssh-keygen -t rsa -b 4096 -C "email@example.com"
    # Save and locate key-pairs files : /home/you/.ssh/id_rsa (EXAMPLE)

User.tfvars should be move to .gitignored
  ** terraform apply -var-file="user.tfvars"

  s3 bucket s3://springboot-s3-example content web app written in Java