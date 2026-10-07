# CI/CD access for GitHub Actions via OIDC: workflows exchange a short-lived
# GitHub token for temporary AWS credentials, so no AWS keys are stored in
# GitHub.
#
#   plan role  - read-only + state lockfile; PRs and pushes to main
#   apply role - can change infrastructure; ONLY jobs running in the
#                "production" GitHub Environment (which requires approval)

# The GitHub OIDC provider already exists in this account (one per URL per
# account), so it is looked up rather than created.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  github_sub_prefix = "repo:${var.github_repository}"
}

# ---------------------------------------------------------------------------
# Plan role
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "github_plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "${local.github_sub_prefix}:pull_request",
        "${local.github_sub_prefix}:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "github_plan" {
  name                 = "${var.project_name}-github-plan"
  description          = "GitHub Actions: terraform plan (read-only)"
  assume_role_policy   = data.aws_iam_policy_document.github_plan_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "github_plan_readonly" {
  role       = aws_iam_role.github_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Plan needs to write/delete the S3 lockfile, and nothing else.
data "aws_iam_policy_document" "state_lock" {
  statement {
    sid       = "StateLockfile"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/${var.state_key_prefix}/*.tflock"]
  }
}

resource "aws_iam_role_policy" "github_plan_state_lock" {
  name   = "terraform-state-lock"
  role   = aws_iam_role.github_plan.id
  policy = data.aws_iam_policy_document.state_lock.json
}

# ---------------------------------------------------------------------------
# Apply role
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "github_apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only jobs bound to the approval-gated environment can assume this role.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.github_sub_prefix}:environment:${var.github_apply_environment}"]
    }
  }
}

resource "aws_iam_role" "github_apply" {
  name                 = "${var.project_name}-github-apply"
  description          = "GitHub Actions: terraform apply (approval-gated)"
  assume_role_policy   = data.aws_iam_policy_document.github_apply_trust.json
  max_session_duration = 3600
}

# PowerUserAccess covers VPC/EC2/ELB/ASG/RDS/Secrets Manager/S3 but no IAM.
resource "aws_iam_role_policy_attachment" "github_apply_poweruser" {
  role       = aws_iam_role.github_apply.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM is granted only for this project's own roles and instance profiles,
# so the pipeline cannot create or modify any other identity.
data "aws_iam_policy_document" "github_apply_iam" {
  statement {
    sid = "ManageProjectRoles"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:GetRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PassRole",
    ]
    resources = ["arn:aws:iam::*:role/${var.project_name}-${var.app_environment}-*"]
  }

  statement {
    sid = "ManageProjectInstanceProfiles"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
    ]
    resources = ["arn:aws:iam::*:instance-profile/${var.project_name}-${var.app_environment}-*"]
  }

  statement {
    sid       = "ServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "autoscaling.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "rds.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy" "github_apply_iam" {
  name   = "project-iam"
  role   = aws_iam_role.github_apply.id
  policy = data.aws_iam_policy_document.github_apply_iam.json
}
