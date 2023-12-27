data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = "adex-terraform-state"
    region  = "us-east-1"
    encrypt = true
    key     = "${data.aws_caller_identity.current.account_id}/sandbox-default-vpc.tfstate"
  }
}
