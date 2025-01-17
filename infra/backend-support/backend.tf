# This file creates S3 bucket to hold terraform states
# and DynamoDB table to keep the state locks.
resource "aws_s3_bucket" "terraform_infra" {
  bucket = "${var.prefix}-terraform-infra"
  force_destroy = true

  # To allow rolling back states
  versioning {
    enabled = true
  }

  # To cleanup old states eventually
  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 90
    }
  }

  tags = {
     Name = "Bucket for terraform states of ${var.prefix}"
     createdBy = "infra/backend-support"
  }
}

resource "aws_s3_bucket_ownership_controls" "terraform_infra" {
  bucket = aws_s3_bucket.terraform_infra.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "terraform_infra" {
  depends_on = [aws_s3_bucket_ownership_controls.terraform_infra]

  bucket = aws_s3_bucket.terraform_infra.id
  acl    = "private"
}

resource "aws_dynamodb_table" "dynamodb-table" {
  name           = "${var.prefix}-terraform-locks"
  # up to 25 per account is free
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
     Name = "Terraform Lock Table"
     createdBy = "infra/backend-support ${var.prefix}"
  }
}
