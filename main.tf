data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

module "blog_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "dev"
  cidr = "10.0.0.0/16"
  azs             = ["sa-east-1a","sa-east-1b","sa-east-1c"]
  public_subnets  = ["10.0.101.0/24","10.0.102.0/24","10.0.103.0/24"]

  tags= {
    Terraform = "true"
    Environment = "dev"
  } 
}

module "blog_alb" {
  source              = "terraform-aws-modules/alb/aws"

  load_balancer_type  = "application"

  vpc_id              = module.blog_vpc.vpc_id
  subnets             = module.blog_vpc.public_subnets
  security_groups     = [module.blog_sg.security_group_id]

  listeners = {
    http_redirect = {
      port = 80
      protocol = "HTTP"
      redirect = {
        port        = 80
        protocol    = "HTTP"
      }
    }
  }

  tags = {
    Environment = "dev"
  }
}

module "blog_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "5.1.2"

  name                = "blog_sg"
  description         = "Allow http and https in. Allow everything out"
  vpc_id              = module.blog_vpc.vpc_id
  ingress_rules       = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.4.1"

  name = "blog_asg"
  min_size = 1
  max_size = 2
  
  vpc_zone_identifier = module.blog_vpc.public_subnets
  security_groups     = [module.blog_sg.security_group_id]
  target_group_arns   = [module.blog_alb.arn]

  image_id            = data.aws_ami.app_ami.id
  instance_type       = "t3.nano"
}