
data "aws_route53_zone" "this" {
  name = "kishanmukundu.co.in"
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name = "www.kishanmukundu.co.in"
  zone_id     = data.aws_route53_zone.this.zone_id
}

module "external_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.env_code}-load-balancer"
  description = "Allow Port 80 TCP inbound traffic to ELB"
  vpc_id      = data.terraform_remote_state.level1.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS to ELB"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "https to ELB"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = var.env_code

  load_balancer_type = "application"

  vpc_id          = data.terraform_remote_state.level1.outputs.vpc_id
  subnets         = data.terraform_remote_state.level1.outputs.public_subnet_id
  security_groups = [module.external_sg.security_group_id]


  target_groups = [
    {
      name_prefix      = var.env_code
      backend_protocol = "HTTP"
      backend_port     = 80

      health_check = {
        enabled             = true
        path                = "/"
        port                = "traffic-port"
        matcher             = 200
        healthy_threshold   = 5
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 30
      }

    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 0
      action_type        = "forward"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Dev"
  }
}

module "dns" {
  source = "terraform-aws-modules/route53/aws//modules/records"

  zone_id = data.aws_route53_zone.this.zone_id

  records = [
    {
      name    = "www"
      type    = "CNAME"
      ttl     = "3600"
      records = [module.alb.lb_dns_name]
    }
  ]



}
