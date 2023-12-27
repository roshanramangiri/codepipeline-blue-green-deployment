module "s3_bucket_for_artifacts" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.application}-artifact"

  force_destroy = var.s3_force_destroy
  create_bucket = var.s3_create_bucket

}