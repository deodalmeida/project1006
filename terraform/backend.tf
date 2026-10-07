# Partial backend configuration. Environment-specific values (bucket, region)
# live in backend.hcl, which is gitignored:
#
#   terraform init -backend-config=backend.hcl
#
# See backend.hcl.example for the expected keys.
terraform {
  backend "s3" {
    key          = "job-readiness/project-1/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
