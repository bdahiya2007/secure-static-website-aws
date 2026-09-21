# Deployment Guide — S3 + CloudFront Static Website (WAF-protected)

This guide walks through deploying the `s3-static-website.yaml` CloudFormation
template and publishing your website content to the resulting S3 bucket,
served through CloudFront and protected by an AWS WAF web ACL.

## Prerequisites

- An AWS account with permissions to create S3 buckets, bucket policies,
  CloudFront distributions, CloudFront Origin Access Control (OAC)
  resources, AWS WAF (WAFv2) web ACLs, and CloudFormation stacks.
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
  (`aws configure`) with valid credentials.
- Your website files (e.g. `index.html`, `error.html`, CSS/JS/images) ready
  in a local folder.
- **Deploy this stack in the `us-east-1` (N. Virginia) region.** AWS WAF
  web ACLs scoped to CloudFront (`Scope: CLOUDFRONT`) must be created in
  `us-east-1` regardless of where your other resources or users are — the
  stack will fail to create the web ACL if deployed elsewhere.

## Files

| File | Purpose |
|---|---|
| `s3-static-website.yaml` | CloudFormation template that creates a private S3 bucket (static website hosting enabled but not publicly reachable), a CloudFront distribution with Origin Access Control (OAC), an AWS WAF web ACL (with the AWS managed SQL injection rule set) attached to the distribution, and a bucket policy that only allows that distribution to read objects. |
| `Deployment.md` | This guide. |

## 1. Choose a bucket name

S3 bucket names must be globally unique across all AWS accounts, lowercase,
and follow S3 naming rules (letters, numbers, dots, hyphens; 3–63
characters). Pick a name now, e.g. `my-company-static-site`.

> **Domain-style names (e.g. `example.com`) are fine to use.** The
> template automatically strips dots when deriving the AWS WAF web ACL's
> `Name` field, since WAF names only allow letters, numbers, underscores,
> and hyphens (no dots) — `example.com` becomes a web ACL named
> `example-com-waf`. Direct HTTPS access to a dotted bucket name has a
> known S3 certificate-matching caveat, but it doesn't apply here since
> the bucket blocks all public access and is only reached through
> CloudFront's signed OAC connection, not a browser hitting the S3
> endpoint directly.

## 2. Deploy the CloudFormation stack

From the directory containing `s3-static-website.yaml`:

```bash
aws cloudformation deploy \
  --template-file s3-static-website.yaml \
  --stack-name my-static-site \
  --region us-east-1 \
  --parameter-overrides BucketName=my-company-static-site
```

Optional parameters you can override:

```bash
aws cloudformation deploy \
  --template-file s3-static-website.yaml \
  --stack-name my-static-site \
  --region us-east-1 \
  --parameter-overrides \
      BucketName=my-company-static-site \
      IndexDocument=index.html \
      ErrorDocument=error.html \
      PriceClass=PriceClass_100
```

This creates:

- An S3 bucket with static website hosting configured, but with **all
  public access blocked**.
- A CloudFront **Origin Access Control (OAC)**.
- An AWS **WAF web ACL** (`Scope: CLOUDFRONT`) with the AWS managed
  `AWSManagedRulesSQLiRuleSet` rule group, actively blocking (not just
  logging) requests that look like SQL injection attempts.
- A **CloudFront distribution** that uses OAC to reach the bucket over the
  S3 REST (regional) endpoint, with the WAF web ACL attached, a managed
  `CachingOptimized` cache policy, and HTTPS-only viewer traffic.
- A bucket policy that grants `s3:GetObject` only to that specific
  CloudFront distribution (scoped via `AWS:SourceArn`) — the bucket itself
  is not publicly reachable.

Note: CloudFront distributions take longer to deploy than a plain S3
website — expect the `deploy` command to take **5–15 minutes**.

## 3. Confirm the stack deployed successfully

```bash
aws cloudformation describe-stacks \
  --stack-name my-static-site \
  --region us-east-1 \
  --query "Stacks[0].StackStatus"
```

You should see `CREATE_COMPLETE` (or `UPDATE_COMPLETE` on redeploys).

## 4. Upload your website content

Sync your local website folder to the bucket:

```bash
aws s3 sync ./website/ s3://my-company-static-site/
```

Re-run this command any time your content changes (see step 7 for cache
invalidation after updates).

## 5. Get the CloudFront URL

Retrieve the distribution's domain name from the stack outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name my-static-site \
  --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontURL'].OutputValue" \
  --output text
```

This returns something like:

```
https://d1234abcdefgh.cloudfront.net
```

Open that URL in a browser to view your live site.

> **Note:** The stack also outputs `S3WebsiteEndpointURL` — the bucket's
> native S3 website endpoint. That endpoint is kept for reference only;
> it is **not** publicly accessible, since the bucket blocks all public
> access. Always use `CloudFrontURL` to view the site.

## 6. Updating the site later

To push content updates, re-run the sync command:

```bash
aws s3 sync ./website/ s3://my-company-static-site/ --delete
```

The `--delete` flag removes files from the bucket that no longer exist
locally — use it carefully.

## 7. Invalidate the CloudFront cache after updates

CloudFront caches content at edge locations, so after syncing new content
you generally need to invalidate the cache for viewers to see the changes
right away. Get the distribution ID from the stack outputs, then create an
invalidation:

```bash
DIST_ID=$(aws cloudformation describe-stacks \
  --stack-name my-static-site \
  --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue" \
  --output text)

aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "/*"
```

CloudFront itself is a global service, so `create-invalidation` doesn't
need a `--region` flag — only the CloudFormation calls above do, since the
stack lives in `us-east-1`.

Invalidating `/*` clears the entire cache and is simplest for small sites.
For larger sites, invalidating only the changed paths reduces cost, since
the first 1,000 invalidation paths per month are free and each path beyond
that is billed.

## 8. View the CloudWatch dashboard (optional)

The stack creates a CloudWatch dashboard showing request volume at both the
CDN layer (CloudFront `Requests`) and the origin layer (S3 `AllRequests`),
so you can see cache-miss traffic hitting the bucket directly. Get its URL
from the stack outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name my-static-site \
  --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='DashboardURL'].OutputValue" \
  --output text
```

Note: S3's `AllRequests` metric isn't published by default — the template
enables it via a bucket-level `MetricsConfigurations` entry, which has its
own small per-metric CloudWatch charge (separate from S3 request costs).

## 9. Check WAF activity (optional)

The web ACL reports sampled requests and CloudWatch metrics under the
`AWS/WAFV2` namespace. To see recent requests the SQL injection rule
blocked:

```bash
WEB_ACL_ARN=$(aws cloudformation describe-stacks \
  --stack-name my-static-site \
  --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='WebACLArn'].OutputValue" \
  --output text)

aws wafv2 get-sampled-requests \
  --web-acl-arn "$WEB_ACL_ARN" \
  --rule-metric-name "my-company-static-site-sqli-rule-set" \
  --scope CLOUDFRONT \
  --time-window StartTime=$(date -u -d '1 hour ago' +%s),EndTime=$(date -u +%s) \
  --max-items 50 \
  --region us-east-1
```

(`--rule-metric-name` should match `<BucketName>-sqli-rule-set` — adjust it
if you used a different `BucketName`.) You can also view this graphically
in the console under **WAF & Shield → Web ACLs → `<bucket-name>-waf` →
Rules → Sampled requests**.

## 10. Tearing down

To delete the stack (and, if the bucket is empty, the bucket itself):

```bash
aws s3 rm s3://my-company-static-site/ --recursive
aws cloudformation delete-stack --stack-name my-static-site --region us-east-1
```

The bucket must be emptied manually first — the template sets a
`Retain` deletion policy on the bucket so CloudFormation won't delete it
automatically, and S3 also won't delete a non-empty bucket.

CloudFront distribution deletion can take several minutes after the stack
delete is initiated, since AWS must first disable the distribution before
it can be removed. `delete-stack` handles this automatically, but the
overall teardown may take longer than the S3-only version of this stack.

## Troubleshooting

If `aws cloudformation deploy` fails with `Failed to create/update the
stack`, get the specific reason with:

```bash
aws cloudformation describe-stack-events \
  --stack-name my-static-site \
  --region us-east-1 \
  --max-items 20 \
  --query "StackEvents[?ResourceStatus=='CREATE_FAILED' || ResourceStatus=='UPDATE_FAILED']"
```

Look at the `ResourceStatusReason` field on the failed resource.

**`CloudFrontWebACL` fails with a validation error mentioning `name` or
`description` regex constraints** — this template already guards against
the most common cause (a `BucketName` containing dots breaking WAF's
`Name` field), but if you've customized the template further, remember
that WAF's `Name`/`MetricName` fields only allow `\w` and hyphens, and
`Description` only allows a narrower set of punctuation — em dashes (—),
curly quotes, and similar "smart" characters aren't accepted; use plain
ASCII hyphens and straight quotes instead.

**Bucket creation fails** — S3 bucket names are globally unique across
*all* AWS accounts, not just yours. If `BucketName` is already taken by
anyone, anywhere, `CloudFrontBucket` creation fails. Pick a different name
and retry.

**Stack stuck in `ROLLBACK_COMPLETE`** — a stack that failed on its very
first create can't be updated in place; delete it and re-deploy:

```bash
aws cloudformation delete-stack --stack-name my-static-site --region us-east-1
aws cloudformation wait stack-delete-complete --stack-name my-static-site --region us-east-1
# then re-run the deploy command from step 2
```

## Notes and next steps

- **HTTPS by default**: unlike the plain S3 website endpoint, CloudFront
  serves the site over HTTPS out of the box, with HTTP requests redirected
  to HTTPS.
- **Custom domain**: to serve the site from your own domain (e.g.
  `www.example.com`) instead of the `*.cloudfront.net` URL, request or
  import a certificate in **ACM** (in `us-east-1`, which CloudFront
  requires), then add it plus your domain to the distribution's
  `Aliases`/`ViewerCertificate` configuration and point a DNS record at the
  CloudFront domain name.
- **Access logging**: consider enabling CloudFront access logs (to a
  separate S3 bucket) and/or S3 server access logging if you need
  visibility into who's accessing the site.
- **WAF protection**: the attached web ACL currently runs only the AWS
  managed `AWSManagedRulesSQLiRuleSet` rule group in blocking mode. If you
  see false positives (legitimate requests being blocked), you can switch
  a rule's `OverrideAction` to `Count: {}` in the template temporarily to
  observe without blocking, then re-enable blocking once tuned. Consider
  adding other AWS managed rule groups (e.g. `AWSManagedRulesCommonRuleSet`
  for broader baseline protection) as additional `Rules` entries with
  increasing `Priority` values.
- **CI/CD**: [.github/workflows/deploy.yml](.github/workflows/deploy.yml)
  automates the sync + invalidation steps above on every push to `main`.
  It authenticates via GitHub OIDC (no long-lived AWS keys stored in
  GitHub) by assuming the `GitHubActionsDeployRole` created by this
  template. To enable it:
  1. Redeploy this stack with `GitHubOrg` and `GitHubRepo` set (and
     `CreateGitHubOIDCProvider=false` if your AWS account already has a
     `token.actions.githubusercontent.com` OIDC provider from another
     stack).
  2. In the GitHub repo's Settings → Secrets and variables → Actions →
     Variables, add:
     - `AWS_ROLE_ARN` — the `GitHubActionsDeployRoleArn` stack output
     - `S3_BUCKET_NAME` — the bucket name
     - `CLOUDFRONT_DISTRIBUTION_ID` — the `CloudFrontDistributionId` output
     - `AWS_REGION` — optional, defaults to `us-east-1`