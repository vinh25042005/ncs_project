terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # Cấu hình lưu trữ State tập trung trên S3 + State Locking
  backend "s3" {
    bucket         = "ncs-project-tfstate-yuzdm6"
    key            = "prod/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "ncs-project-tflocks"
    use_lockfile   = true
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}
