terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# S3 bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

# Required so the bucket policy below can grant public read access
resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Static website hosting requires the bucket (and its objects) to be
# publicly readable, so the account/bucket-level public access blocks
# must be disabled.
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# -----------------------------------------------------------------------------
# Static website hosting configuration
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# -----------------------------------------------------------------------------
# Bucket policy - allow public GetObject so the website is reachable
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "public_read" {
  statement {
    sid       = "PublicReadAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.public_read.json

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# -----------------------------------------------------------------------------
# Upload website files from the local ./www directory
# -----------------------------------------------------------------------------
locals {
  mime_types = {
    ".html" = "text/html"
    ".htm"  = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".txt"  = "text/plain"
  }
}

resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/www", "**")

  bucket = aws_s3_bucket.website.id
  key    = each.value
  source = "${path.module}/www/${each.value}"
  etag   = filemd5("${path.module}/www/${each.value}")

  content_type = lookup(
    local.mime_types,
    regex("\\.[^.]+$", each.value),
    "application/octet-stream"
  )

  depends_on = [
    aws_s3_bucket_ownership_controls.website,
    aws_s3_bucket_policy.website
  ]
}
