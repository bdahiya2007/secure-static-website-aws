# Security policy

This is a personal portfolio project, not a supported product. Security reports are still welcome, and are handled on a best-effort basis.

## Reporting a vulnerability

Please report it **privately**, not in a public issue or pull request:

1. Open the repository's **Security** tab.
2. Choose **Report a vulnerability** (GitHub private vulnerability reporting).
3. Describe what you found, where, and how to reproduce it. Do not include real credentials or other people's data.

You can expect an acknowledgement within about a week and a fix or a decision as time allows. Please give me a reasonable chance to fix the
issue before sharing details publicly.

## What is in scope

- `s3-static-website.yaml`, `s3-static-website-dr.yaml`, the site in `s3-static-website/`, `deploy.sh`, the GitHub Actions workflow and the
  documentation: for example a way to reach either S3 bucket other than through CloudFront, a weakness in the WAF rules or the security
  headers and Content Security Policy, a way for a pull request to change the live site, a weakness in either GitHub OIDC role's trust
  policy or permissions, or a secret committed by mistake.

## What is out of scope

- The `terraform/` directory. It is the deliberately minimal comparison path described under
  [Two IaC paths, on purpose](README.md#two-iac-paths-on-purpose), and its public-read bucket and missing HTTPS are by design.
- Findings that need access to the owner's AWS or GitHub account.
- Weaknesses in AWS or GitHub themselves.
- The demo storefront's cart and checkout. They run only in the browser, with no back end, payments or accounts behind them.
- Denial-of-service testing, load testing, WAF rule probing or any other testing against the live site. It belongs to the owner and is not
  offered for testing; please review the code instead.

## Supported versions

Only the latest commit on `main` is maintained.

## If you find a secret

If you find what looks like a real credential in the repository or its history, report it privately as above. It will be rotated first,
then removed. No AWS access keys are used anywhere: the workflow authenticates with short-lived GitHub OIDC tokens.
