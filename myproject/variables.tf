provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "wargaming-test-terraform-state" // Bucket where to SAVE Terraform State
    key    = "dev/terraform.tfstate"          // Object name in the bucket to SAVE Terraform State
    region = "eu-central-1"                   // Region where bucket is created
  }
}

variable "env" {
  default = "dev"
}

variable "common_tags" {
  description = "Common Tags to apply to all resources"
  default = {
    Owner   = "Dmitriy Lazarev"
    Project = "Wargaming-Test"
  }
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "vpc_public_subnet_cidrs" {
  type = list(any)
  default = [
    "10.1.0.0/24",
    # "10.2.0.0/24",
    # "10.3.0.0/24",
  ]
}

variable "allow_ports" {
  description = "List of Ports to open for server"
  type        = list(any)
  default     = ["80", "443"]
}

variable "default_instance_count" {
  default = 1
}

variable "default_instance_type" {
  default = "t2.nano"
}

variable "default_key" {
  default = "wgmoscow-test"
}
