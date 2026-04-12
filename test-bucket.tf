terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "shawn-terraform-state-2026"
    key     = "jenkins-s3-test/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "jenkins-bucket-"
  force_destroy = true

  tags = {
    Name = "Jenkins Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend_public_read" {
  bucket = aws_s3_bucket.frontend.id

  depends_on = [aws_s3_bucket_public_access_block.frontend_public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "armageddon_approval" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "armageddon-approval.png"
  source       = "${path.module}/files/armageddon-approval.png"
  etag         = filemd5("${path.module}/files/armageddon-approval.png")
  content_type = "image/png"
}

resource "aws_s3_object" "repo_links" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "repo-links.rtf"
  source       = "${path.module}/files/repo-links.rtf"
  etag         = filemd5("${path.module}/files/repo-links.rtf")
  content_type = "application/rtf"
}

resource "aws_s3_object" "bucket_items" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "bucket-items.png"
  source       = "${path.module}/files/bucket-items.png"
  etag         = filemd5("${path.module}/files/bucket-items.png")
  content_type = "image/png"
}

resource "aws_s3_object" "webhook_trigger" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "webhook-trigger.png"
  source       = "${path.module}/files/webhook-trigger.png"
  etag         = filemd5("${path.module}/files/webhook-trigger.png")
  content_type = "image/png"
}

resource "aws_s3_object" "jenkins_success" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "jenkins-success.png"
  source       = "${path.module}/files/jenkins-success.png"
  etag         = filemd5("${path.module}/files/jenkins-success.png")
  content_type = "image/png"
}