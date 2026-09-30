# Assignment 1 — Bootstrap Terraform Remote State

## Objective
Write the Terraform yourself. Your goal is to create the S3 backend that the main infrastructure will use for remote state.

## Create these files yourself

```text
bootstrap/
├── versions.tf
├── variables.tf
├── main.tf
└── outputs.tf
```

Do **not** copy a completed solution from another repository. Use the Terraform Registry/provider documentation when you need resource syntax.

## Requirements

Your Terraform must:

1. Configure Terraform and the AWS provider.
2. Accept the AWS Region and project name as variables.
3. Create an S3 bucket with a globally unique name for Terraform state.
4. Enable bucket versioning.
5. Enable server-side encryption.
6. Block all public access.
7. Protect the state bucket from accidental deletion using an appropriate Terraform lifecycle rule.
8. Output the bucket name and AWS Region.

## Acceptance criteria

Run:

```bash
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
terraform apply
```

Then verify:

```bash
aws s3api get-bucket-versioning --bucket <YOUR_BUCKET>
aws s3api get-public-access-block --bucket <YOUR_BUCKET>
aws s3api get-bucket-encryption --bucket <YOUR_BUCKET>
```

You should be able to explain why Terraform state should not normally live only on an engineer's laptop.

## Hint
Think about separate resources/settings for the bucket itself, versioning, encryption, and public-access blocking. For the main project, use S3 native state locking with `use_lockfile = true`.

## Checkpoint questions

- What information can Terraform state contain?
- Why enable versioning on a state bucket?
- Why should the backend be created before the main infrastructure?
- What problem does state locking solve?
