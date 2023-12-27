################################################################################
# AutoScaling Group
################################################################################

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.10"

  # Autoscaling group
  name = "${var.application}-asg"

  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.route53_zone_id.private_subnets ####need to be changed
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  image_id                    = module.ubuntu_20_04_latest.ami.image_id
  instance_type               = var.instance_type
  capacity_rebalance          = true
  create_iam_instance_profile = false
  iam_instance_profile_arn    = aws_iam_instance_profile.ec2_instance_profile.arn
  security_groups             = [module.sg_asg.security_group_id]

  enable_monitoring = true
  user_data = base64encode(<<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y python3.10
    sudo apt-get install -y ruby-full
    sudo apt-get install -y wget
    cd /home/ubuntu
    wget https://aws-codedeploy-${var.region}.s3.${var.region}.amazonaws.com/latest/install
    sudo chmod +x ./install
    sudo ./install auto > /tmp/logfile
    sudo apt-get install -y python3-pip
    sudo pip3 install awscli
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
    sudo rm -rf amazon-cloudwatch-agent.deb install
    sudo apt-get install -y libcurl4-openssl-dev libssl-dev
    sudo apt-get install mysql-client
    sudo apt-get install python3-dev default-libmysqlclient-dev
    sudo apt-get install pkg-config
    sudo apt-get install -y nginx supervisor
    aws --profile default configure set region "${var.region}"

    #Setting up a environment variable
    cat << EOF > /etc/profile.d/script.sh
    export AWS_REGION=${var.region}
    export PROJECT_NAME=${var.application}
    EOF
    source /etc/profile.d/script.sh
    mkdir /home/ubuntu/todo-app
  EOT
  )


  target_group_arns = module.alb.target_group_arns

  initial_lifecycle_hooks = [
    {
      name                 = "ExampleStartupLifeCycleHook"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 60
      lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
      # This could be a rendered data resource
      notification_metadata = jsonencode({ "hello" = "world" })
    },
    {
      name                 = "ExampleTerminationLifeCycleHook"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 180
      lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
      # This could be a rendered data resource
      notification_metadata = jsonencode({ "goodbye" = "world" })
    }
  ]
  tag_specifications = [
    {
      resource_type = "instance"
      tags          = var.tags
    },
    {
      resource_type = "volume"
      tags          = var.tags
    }
  ]
}

module "ubuntu_20_04_latest" {
  source   = "github.com/andreswebs/terraform-aws-ami-ubuntu?ref=23a76c9"
  ami_slug = "ubuntu-jammy-22.04"
}


module "sg_asg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.application}-autoscaling-sg"
  description = "Autoscaling group security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.route53_zone_id.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.sg_alb.security_group_id
    },
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.sg_alb.security_group_id

    },
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.rds_security_group.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 3

  egress_rules = ["all-all"]
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.application}-ec2_role"
  assume_role_policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.application}-ec2-policy"
  role = aws_iam_role.ec2_role.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "efsmount",
        "Effect" : "Allow",
        "Action" : [
          "ssm:DescribeParameters",
          "ssm:GetParameterHistory",
          "ssm:DescribeDocumentParameters",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ec2:DescribeTags",
          "iam:PassRole",
          "ec2:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment_cw" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}


#Creating EC2 instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.application}-ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}