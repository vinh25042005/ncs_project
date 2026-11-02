# Bootstrap: Tạo S3 Bucket lưu State & DynamoDB Table để State Locking

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "project_name" {
  type    = string
  default = "ncs-project"
}

# Tạo chuỗi ngẫu nhiên để tên S3 Bucket là duy nhất
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# S3 Bucket lưu  Terraform State &  .tfvars
resource "aws_s3_bucket" "tfstate" {
  bucket        = "${var.project_name}-tfstate-${random_string.suffix.result}"
  force_destroy = false

  tags = {
    Name        = "${var.project_name}-tfstate"
    Environment = "Management"
  }
}

# Bật Versioning để khôi phục lại State cũ nếu có lỗi
resource "aws_s3_bucket_versioning" "tfstate_versioning" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bật mã hóa máy chủ 
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_crypto" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Chặn hoàn toàn truy cập công khai (Public Access) vào State & file Vars
resource "aws_s3_bucket_public_access_block" "tfstate_block_public" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. DynamoDB Table để State Locking
resource "aws_dynamodb_table" "tflocks" {
  name         = "${var.project_name}-tflocks"
  billing_mode = "PAY_PER_REQUEST" 
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-tflocks"
    Environment = "Management"
  }
}

output "s3_bucket_name" {
  description = "Tên S3 Bucket đã tạo để điền vào backend trong main.tf"
  value       = aws_s3_bucket.tfstate.id
}

output "dynamodb_table_name" {
  description = "Tên DynamoDB Table dùng để khóa State"
  value       = aws_dynamodb_table.tflocks.name
}

output "backend_config_snippet" {
  description = "Cấu hình backend copy vào terraform/versions.tf"
  value       = <<-EOT
    backend "s3" {
      bucket         = "${aws_s3_bucket.tfstate.id}"
      key            = "prod/terraform.tfstate"
      region         = "${var.region}"
      encrypt        = true
      dynamodb_table = "${aws_dynamodb_table.tflocks.name}"
    }
  EOT
}
