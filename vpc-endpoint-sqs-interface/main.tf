locals {
    vm_specific_settings = {
        linux_bastion_host = {
            vpc_security_group_ids      = ["${aws_security_group.public.id}"]
            subnet_id                   = module.vpc.public_subnets[0]
            associate_public_ip_address = true
        }

        ec2_private_instance =  {
            vpc_security_group_ids      = ["${aws_security_group.private.id}"]
            subnet_id                   = module.vpc.private_subnets[0]
            associate_public_ip_address = false
        }
    }

}


#####################################################################################################################
# VPC Module reference link: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
# Create the VPC resource
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.0.99.0/24"]
  public_subnets  = ["10.0.10.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
#####################################################################################################################

#####################################################################################################################
# Create the Security Groups
resource "aws_security_group" "public" {
  name        = "public_SG"
  description = "Public Security Group"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.default_public_ingress
    content {
      description = ingress.value["description"]
      from_port   = ingress.key
      to_port     = ingress.key
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }

  dynamic "egress" {
    for_each = var.default_public_egress
    content {
      description = egress.value["description"]
      from_port   = egress.key
      to_port     = egress.key
      protocol    = egress.value["protocol"]
      cidr_blocks = egress.value["cidr_blocks"]
    }
  }

  tags = {
    Terraform   = "true"    
    Environment = "dev"
  }
}

resource "aws_security_group" "private" {
  name        = "Private_SG"
  description = "Private Security Group"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.default_private_ingress
    content {
      description = ingress.value["description"]
      from_port   = ingress.key
      to_port     = ingress.key
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }

  dynamic "egress" {
    for_each = var.default_private_egress
    content {
      description = egress.value["description"]
      from_port   = egress.key
      to_port     = egress.key
      protocol    = egress.value["protocol"]
      cidr_blocks = egress.value["cidr_blocks"]
    }
  }

  tags = {
    Terraform   = "true"    
    Environment = "dev"
  }
}
#####################################################################################################################


#####################################################################################################################
# Get the latest amazon linux version
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

#Create the EC2 resource
resource "aws_instance" "this" {

    for_each = local.vm_specific_settings 

    ami                         = data.aws_ami.amazon_linux.id
    instance_type               = "t2.micro"
    subnet_id                   = each.value.subnet_id
    associate_public_ip_address = each.value.associate_public_ip_address
    vpc_security_group_ids      = each.value.vpc_security_group_ids
    key_name                    = "Key-Linux-AWS"

    #Assigning the IAM Role to EC2 Instance. The role permit to list, get, and put S3 Buckets. The role will assign only to the "ec2_private_instance" 
    iam_instance_profile = each.key == "ec2_private_instance" ? aws_iam_instance_profile.demo-profile.name : null
    
    root_block_device {  
        volume_size = 20
    }
    tags = {
        Name = each.key
    }
}
#################################################################################################################

#################################################################################################################
#Create a IAM Role
resource "aws_iam_role" "this" {
  name = "EC2_SQSFullAccess"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

#Create a IAM Policy and assign to the IAM Role
resource "aws_iam_role_policy" "this" {
  name = "SQSFullAccess"
  role = aws_iam_role.this.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sqs:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
    ]
  })
}



# Create an instance profile using role
resource "aws_iam_instance_profile" "demo-profile" {
    name = "demo_profile"
    role = aws_iam_role.this.name
}
#################################################################################################################

#################################################################################################################
# #Create a S3 bucket
# resource "aws_s3_bucket" "this" {
#   bucket = "s3-bucket-vpce-connection"

#   tags = {
#     Name        = "My bucket"
#     Environment = "Dev"
#     Terraform   = "True"
#   }
# }
#################################################################################################################

#################################################################################################################
# # Create the VPC Endpoint Gateway to access the S3 bucket. Assign the endpoint to all private route tables 
# #to create a route for reaching the prefix list with all Network space belonging to the S3.
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = module.vpc.vpc_id
#   service_name      = "com.amazonaws.us-east-1.s3"
#   route_table_ids   = module.vpc.private_route_table_ids
# }

#sqs QUEUE - https://www.howtoforge.com/how-to-create-an-sqs-queue-on-aws-using-terraform/

# resource "aws_sqs_queue" "my_first_sqs" {
#   name = var.sqs_name
# }

# resource "aws_sqs_queue_policy" "my_sqs_policy" {
#   queue_url = aws_sqs_queue.my_first_sqs.id

#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Id": "sqspolicy",
#   "Statement": [
#     {
#       "Sid": "First",
#       "Effect": "Allow",
#       "Principal": "*",
#       "Action": "sqs:SendMessage",
#       "Resource": "${aws_sqs_queue.my_first_sqs.arn}"
#     }
#   ]
# }
# POLICY
# }