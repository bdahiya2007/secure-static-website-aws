output "website_endpoint" {
  description = "S3 static website endpoint URL (HTTP only)"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket (useful when fronting with CloudFront)"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}
