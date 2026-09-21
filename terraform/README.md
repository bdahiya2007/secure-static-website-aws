# S3 Static Website - Terraform

Deploys an S3 bucket configured for static website hosting and uploads the
contents of the `www/` folder to it.

## Files
- `main.tf` - bucket, public access settings, website config, bucket policy, file uploads
- `variables.tf` - input variables
- `outputs.tf` - website endpoint and bucket info
- `terraform.tfvars.example` - sample variable values
- `www/` - your website source files (index.html, error.html, add your own here)

## Usage

```bash
# 1. Copy the example vars file and set a globally-unique bucket name
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your bucket name / region

# 2. Init, plan, apply
terraform init
terraform plan
terraform apply
```

After apply completes, Terraform prints `website_endpoint` — open that URL
in a browser to view the site.

## Adding more pages/assets
Drop any additional files (CSS, JS, images, extra HTML pages) into `www/`.
The `aws_s3_object.website_files` resource uploads every file in that folder
automatically on the next `terraform apply` — no extra config needed. Common
extensions already have correct `Content-Type` mappings in `main.tf`
(`local.mime_types`); add more entries there if you use other file types.

## Notes
- The S3 website endpoint is HTTP only. For HTTPS, a custom domain, or
  better performance, put CloudFront in front of the bucket — happy to add
  that if you want it.
- The bucket is made publicly readable (`s3:GetObject` for everyone), which
  is required for S3 static website hosting to work without CloudFront.
- `bucket_name` must be globally unique across all of AWS S3.

## Cleanup
```bash
terraform destroy
```
