# Assignment 2 — Build the AWS 3-Tier Infrastructure

You are the Terraform engineer for this project. The application code is already provided in `app/`; **all infrastructure Terraform is your responsibility**.

## Target architecture

Build:

```text
Internet
   |
   v
Public ALB (2 public subnets / 2 AZs)
   |
   v
EC2 Auto Scaling Group (2 private app subnets)
   |
   v
RDS PostgreSQL (private DB subnets)
```

Supporting services: IAM instance role/profile, Systems Manager, Secrets Manager-managed RDS password, NAT Gateway, CloudWatch/AWS metrics, and remote S3 Terraform state.

## Suggested files to create

You choose the exact organization, but a good professional layout is:

```text
terraform/
├── versions.tf
├── backend.tf
├── variables.tf
├── terraform.tfvars
├── locals.tf
├── data.tf
├── network.tf
├── security.tf
├── iam.tf
├── rds.tf
├── compute.tf
├── alb.tf
├── outputs.tf
└── scripts/
    └── user_data.sh.tftpl
```

The filenames are guidance, not solutions.

---

## Task 1 — Terraform configuration and variables

Configure Terraform and the AWS provider. Create variables instead of hardcoding values that may change between environments.

Minimum configurable values:

- AWS Region: `us-east-1`
- Project name
- Environment
- VPC CIDR: `10.20.0.0/16`
- EC2 instance type: `t3.micro`
- RDS instance class: `db.t4g.micro`
- Desired/min/max ASG capacity

### Acceptance criteria

```bash
terraform fmt -check -recursive
terraform init
terraform validate
```

Explain the difference between a variable, local value, data source, resource, and output.

---

## Task 2 — Networking

Create:

- 1 VPC — `10.20.0.0/16`
- 2 public subnets in different AZs
- 2 private application subnets in different AZs
- 2 private database subnets in different AZs
- Internet Gateway
- 1 NAT Gateway for the lab
- Elastic IP for the NAT Gateway
- Public route table and route to the Internet Gateway
- Private application route table and outbound route through NAT
- Database route table with no direct Internet route
- All required route-table associations

Choose non-overlapping subnet CIDRs yourself and document them in the README or comments.

### Checkpoint

Use AWS CLI or the console to prove:

- Public subnets have a route to the IGW.
- App subnets do **not** route directly to the IGW.
- DB subnets do **not** have a direct Internet route.
- Resources span two AZs.

### Interview question
Why do private EC2 instances need NAT but the ALB does not?

---

## Task 3 — Security groups

Implement this traffic model:

```text
Internet --80--> ALB
ALB SG --8000--> Application EC2
Application SG --5432--> PostgreSQL
```

Requirements:

- No SSH/22 inbound rule.
- RDS must never accept `0.0.0.0/0` on 5432.
- Prefer security-group references between tiers instead of CIDR rules.

### Checkpoint
Explain why allowing port 8000 only from the ALB SG is stronger than allowing it from the whole VPC CIDR.

---

## Task 4 — IAM and Systems Manager

Create an EC2 IAM role and instance profile.

The instances must be able to:

- register with Systems Manager / Session Manager;
- retrieve only the database secret they need;
- run without an SSH key pair.

Do not attach AdministratorAccess.

### Checkpoint
Connect to an instance using Session Manager and prove port 22 is not open.

---

## Task 5 — PostgreSQL RDS

Create:

- DB subnet group using the two private DB subnets;
- PostgreSQL RDS instance;
- storage encryption;
- `publicly_accessible = false` behavior;
- database SG from Task 3;
- AWS-managed master password in Secrets Manager rather than a password committed to Git.

For the base lab, Single-AZ is acceptable to control cost. Multi-AZ is a stretch goal.

### Checkpoint
Prove that the DB is not public and identify the secret AWS created for its credentials.

---

## Task 6 — EC2 launch template and Auto Scaling

Create a launch template and Auto Scaling Group.

Requirements:

- Amazon Linux 2023 AMI discovered with a data source rather than a hardcoded AMI ID;
- EC2 instances only in private application subnets;
- IAM instance profile from Task 4;
- application SG from Task 3;
- IMDSv2 required;
- minimum 2 application instances for the base lab;
- user data installs the application dependencies and starts the provided Flask app on port `8000`;
- instances obtain database credentials at runtime rather than embedding the password in Terraform/user data.

The provided application lives in `../app/`. Decide how your bootstrap process will make the application available to new instances. Document your choice.

### Checkpoint
Terminate one application instance. The ASG must replace it automatically.

---

## Task 7 — Application Load Balancer

Create:

- internet-facing ALB in both public subnets;
- target group for application port `8000`;
- health check path `/health`;
- HTTP listener on port `80` for the base lab;
- ASG attachment to the target group.

### Checkpoint

```bash
aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN>
```

You need two healthy targets before moving on.

---

## Task 8 — Outputs

At minimum, output useful non-secret values for:

- application URL / ALB DNS name;
- VPC ID;
- target group ARN;
- Auto Scaling Group name;
- RDS endpoint or identifier as appropriate.

Never output the database password.

---

## Task 9 — Remote backend

After completing the bootstrap assignment, configure the main Terraform project to use the S3 bucket.

Backend requirements:

```text
key: job-readiness/project-1/terraform.tfstate
encryption: enabled
S3 lockfile: enabled
```

Do not commit environment-specific backend values or state files to Git.

---

## Task 10 — Validate the complete system

Run:

```bash
terraform fmt -check -recursive
terraform validate
terraform plan
terraform apply
```

Then complete `../validation/checklist.md` and the troubleshooting exercises.

## Definition of done

The project is complete only when you can:

1. Draw the architecture without looking at the repository.
2. Explain the request path from Internet → ALB → EC2 → RDS.
3. Explain every security-group rule.
4. Explain how a private EC2 instance reaches AWS/public endpoints.
5. Explain where the database password lives and who can retrieve it.
6. Replace a failed EC2 instance through Auto Scaling.
7. Diagnose an unhealthy ALB target.
8. Destroy and recreate the environment with Terraform.
9. Explain the project in a 2–3 minute interview answer.
