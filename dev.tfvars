################################################################################
# Input local variables
################################################################################

environment = "dev"
application = "gameday-bluegreen" #need to be changed
owner       = "roshan.giri"
region = "us-east-1"

instance_type = "t2.micro"
volume_size = 8
volume_type = "gp2"
enable_nat_gateway = false

db_instance_type = "db.t3.micro"
db_allocated_storage = 20
db_max_allocated_storage = 100
skip_final_snapshot = true
deletion_protection = false

github_repo_branch = "main"
github_repo_name   = "todo-app"
github_repo_owner  = "roshanramangiri"
