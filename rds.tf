###############################################################################
# RDS
###############################################################################

module "db" {
  source     = "terraform-aws-modules/rds/aws"
  version    = "5.9.0"
  identifier = var.application
  depends_on = [aws_db_subnet_group.gameday]


  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"         # DB option group
  instance_class       = var.db_instance_type

  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = var.db_max_allocated_storage
  create_random_password = false

  db_name  = aws_ssm_parameter.database_name.value
  username = aws_ssm_parameter.database_user.value
  password = aws_ssm_parameter.database_password.value
  port     = 3306

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.gameday.name
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

}
resource "aws_db_subnet_group" "gameday" {
  name       = "gameday-db-subnet-group"
  subnet_ids = data.terraform_remote_state.vpc.outputs.route53_zone_id.private_subnets
}

module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = var.application
  description = "Complete mysql security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.route53_zone_id.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "mysql access from within VPC"
      cidr_blocks = data.terraform_remote_state.vpc.outputs.route53_zone_id.vpc_cidr_block
    },
  ]
}
