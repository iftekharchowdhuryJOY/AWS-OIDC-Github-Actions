terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1" # Change this if you use a different region
}

# 📝 CONFIGURATION
locals {
  github_user = "iftekharchowdhuryJOY"
  github_repo = "AI-Log-Analyzer"
}

# 1️⃣ CREATE THE TRUST PROVIDER (The Handshake)
# This tells AWS: "We trust GitHub's token server"
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # This is GitHub's public certificate thumbprint (Standard value)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 2️⃣ CREATE THE IAM ROLE (The Hat)
# This is the role GitHub Actions will "put on"
resource "aws_iam_role" "github_oidc_role" {
  name = "GitHubActions-OIDC-Role-TF"

  # TRUST POLICY: Who can wear this hat?
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
            # 🔒 SECURITY: Only allow THIS specific repo to use the role
            "token.actions.githubusercontent.com:sub": "repo:${local.github_user}/${local.github_repo}:*"
          }
        }
      }
    ]
  })
}

# 3️⃣ ATTACH PERMISSIONS
# Giving the role permission to read S3 (Safe for testing)
resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# 4️⃣ OUTPUT THE ARN
# We need this to paste into our GitHub Actions YAML
output "role_arn" {
  description = "Copy this ARN into your GitHub Actions YAML"
  value       = aws_iam_role.github_oidc_role.arn
}