#!/bin/bash
set -e

# Đọc tên bucket từ backend trong main.tf
BUCKET=$(grep -E '^\s*bucket\s*=' versions.tf | awk -F'"' '{print $2}')
S3_VARS_PATH="s3://${BUCKET}/vars/terraform.tfvars"

usage() {
  echo "Sử dụng:"
  echo "  $0 push-vars      - Đẩy file terraform.tfvars local lên S3 (mã hóa)"
  echo "  $0 pull-vars      - Tải file terraform.tfvars từ S3 về máy local"
  echo "  $0 plan           - Chạy terraform plan với biến nạp trực tiếp từ S3"
  echo "  $0 apply          - Chạy terraform apply với biến nạp trực tiếp từ S3"
  exit 1
}

case "$1" in
  push-vars)
    if [ ! -f "terraform.tfvars" ]; then
      echo "Lỗi: Không tìm thấy file terraform.tfvars ở local."
      exit 1
    fi
    echo ">>> Đang đẩy terraform.tfvars lên ${S3_VARS_PATH}..."
    aws s3 cp terraform.tfvars "${S3_VARS_PATH}" --sse AES256
    echo ">>> Đã đồng bộ file biến lên S3 thành công!"
    ;;

  pull-vars)
    echo ">>> Đang tải file biến từ ${S3_VARS_PATH} về máy..."
    aws s3 cp "${S3_VARS_PATH}" terraform.tfvars
    echo ">>> Đã tải thành công terraform.tfvars!"
    ;;

  plan)
    echo ">>> Đang chạy terraform plan với biến từ S3..."
    terraform plan -var-file=<(aws s3 cp "${S3_VARS_PATH}" -)
    ;;

  apply)
    echo ">>> Đang chạy terraform apply với biến từ S3..."
    terraform apply -var-file=<(aws s3 cp "${S3_VARS_PATH}" -)
    ;;

  *)
    usage
    ;;
esac
