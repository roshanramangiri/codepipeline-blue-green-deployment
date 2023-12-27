################################################################################
# Application Load Balancer
################################################################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "${var.application}-alb"

  load_balancer_type = "application"

  vpc_id          = data.terraform_remote_state.vpc.outputs.route53_zone_id.vpc_id
  subnets         = data.terraform_remote_state.vpc.outputs.route53_zone_id.public_subnets
  security_groups = [module.sg_alb.security_group_id]

  target_groups = [
    {
      name_prefix      = "gd-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health_check"
        port                = 80
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
      }
    }
  ]
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
}

module "sg_alb" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.application}-alb-sg"
  description = "Service security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.route53_zone_id.vpc_id

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = data.terraform_remote_state.vpc.outputs.route53_zone_id.private_subnets_cidr_blocks

}