################################################################################
# Input variables for the main.tf file
################################################################################

variable "environment" {
  description = "Working application environment eg: dev, stg, prd"
  type        = string
  default     = ""
}

variable "application" {
  description = "Name of the application"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region be used for all the resources"
  type        = string
  default     = "us-east-1"
}

variable "enable_nat_gateway" {
  description = "Enable or disable the nat gateway"
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "Type of the instance"
  type        = string
  default     = "t2.micro"
}

variable "volume_type" {
  description = "Type of the volume"
  type        = string
  default     = "gp2"
}

variable "volume_size" {
  description = "volume size"
  type = number
}

variable "db_instance_type" {
  description = "Instance type of the Database"
  type = string
}

variable "db_allocated_storage" {
  description = "Allocated storage of the Database"
  type = number
}

variable "db_max_allocated_storage" {
  description = "Max allocated storage of the Database"
  type = number
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot of the Database"
  type = bool
  default = true
}

variable "deletion_protection" {
  description = "Deletion protection of the Database"
  type = bool
  default = false
}

variable "s3_create_bucket" {
  description = "Create s3 bucket"
  type = bool
  default = true
}

variable "s3_force_destroy" {
  description = "Force destroy s3 bucket"
  type = bool
  default = true
}

variable "github_repo_owner" {
  description = "Name of the github repo owner"
  type        = string
}

variable "github_repo_name" {
  description = "Name of the github repo name"
  type        = string
}

variable "github_repo_branch" {
  description = "Name of the github order branch"
  type        = string
}

variable "tags" {
  description = "Tags"
  default = {
      owner       = "roshan.giri"
      Environment = "dev"
      Application = "gameday"
      silo        = "devsecops"
      project     = "bluegreen"
      terraform   = "true"
    }
}