module "private_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~>4.0"

  name        = "${var.env_code}-Private"
  description = "Allow prot 80 and 3308 inbound to EC2 ASG within VPC"
  vpc_id      = data.terraform_remote_state.level1.outputs.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.external_sg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "http to ELB"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

module "autoscaling" {
  source = "terraform-aws-modules/autoscaling/aws"

  name                      = "var.env_code"
  min_size                  = 2
  max_size                  = 5
  desired_capacity          = 2
  health_check_grace_period = 400
  health_check_type         = "EC2"
  vpc_zone_identifier       = data.terraform_remote_state.level1.outputs.private_subnet_id
  target_group_arns         = module.alb.target_group_arns
  force_delete              = true

  launch_template_name        = var.env_code
  launch_template_description = "launch template example"
  update_default_version      = true
  launch_template_version     = "$Latest"

  image_id        = data.aws_ami.amazonlinux.id
  instance_type   = "t2.micro"
  key_name        = "main"
  security_groups = [module.private_sg.security_group_id]
  user_data       = filebase64("userdata.sh")

  create_iam_instance_profile = true
  iam_role_name               = var.env_code
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM Role for Sessions manager"
  iam_role_tags = {
    CustomIamRole = "No"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}
