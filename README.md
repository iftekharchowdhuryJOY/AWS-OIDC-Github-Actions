# 🏗️ AWS OIDC & GitHub Actions (Terraform Guide)

This guide documents the **Infrastructure as Code (IaC)** method to connect GitHub Actions to AWS. This is the preferred, professional way to manage permissions.

## 📂 Step 1: The Terraform Code
Create a file named `oidc.tf` and add the following configuration.

**Requirements:**
* `hashicorp/aws` provider version 5.0+
* Your GitHub Organization and Repository name

```hcl
provider "aws" {
  region = "us-east-1"
}

# 📝 VARIABLES
locals {
  github_user = "iftekharchowdhuryJOY"
  github_repo = "my-tech-blog"
}

# 1️⃣ TRUST PROVIDER (The Handshake)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "[https://token.actions.githubusercontent.com](https://token.actions.githubusercontent.com)"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 2️⃣ IAM ROLE (The Hat)
resource "aws_iam_role" "github_oidc_role" {
  name = "GitHubActions-OIDC-Role-TF"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            # 🔒 SECURITY: Locks access to YOUR specific repo
            "token.actions.githubusercontent.com:sub": "repo:${local.github_user}/${local.github_repo}:*"
          }
        }
      }
    ]
  })
}

# 3️⃣ ATTACH PERMISSIONS
resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# 4️⃣ OUTPUT ARN
output "role_arn" {
  value = aws_iam_role.github_oidc_role.arn
}

```

## 🚀 Step 2: Deploy

Run these commands in your terminal:

1. `terraform init` - Downloads the AWS plugins.
2. `terraform apply` - Creates the resources in AWS.
3. **Copy the Output:** Copy the `role_arn` displayed at the end.

## 🤖 Step 3: Update GitHub Action

Update your `.github/workflows/oidc-test.yml` with the new ARN:

```yaml
    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v3
      with:
        role-to-assume: arn:aws:iam::123456789012:role/GitHubActions-OIDC-Role-TF # <--- Paste Terraform Output here
        aws-region: us-east-1


## 🧹 Cleanup (Destruction)

To remove all resources and stop paying for them (or clean up the account):

```bash
terraform destroy



