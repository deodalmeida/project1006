# Interview Prep

The objective is not to memorize definitions. Explain the project as something you designed, deployed, validated, broke, and repaired.

## 60-second project explanation

Practice a version similar to this in your own words:

> I built a three-tier AWS application entirely with Terraform. The public tier uses an Application Load Balancer across two Availability Zones. The application tier uses an Auto Scaling Group of EC2 instances in private subnets, and the database tier uses private RDS PostgreSQL subnets. Security groups enforce ALB-to-app and app-to-database traffic only. I removed SSH access and used Systems Manager instead. RDS manages its password in Secrets Manager, and the EC2 IAM role can read only that database secret. I also implemented remote Terraform state with S3 state locking and tested failure scenarios such as unhealthy load-balancer targets, broken database security groups, IAM AccessDenied errors, and EC2 instance replacement.

## Architecture questions

1. Why did you place the ALB in public subnets but EC2 in private subnets?
2. What makes a subnet public?
3. Why does the application tier need a NAT Gateway?
4. Why does the database subnet not need a default Internet route?
5. Why use two Availability Zones?
6. What changes would you make for a real production deployment?
7. What is the difference between an ALB security group and an EC2 security group in this design?

## Terraform questions

1. What information is stored in Terraform state?
2. Why should state be remote for a team?
3. What problem does state locking solve?
4. Why is creating the backend bucket usually a separate bootstrap step?
5. Difference between a variable, local, data source, resource, and output?
6. What happens during `terraform plan`?
7. What would you do if someone manually changed an AWS resource outside Terraform?
8. When would you use `terraform import`?
9. Why avoid storing passwords in `terraform.tfvars`?
10. What is lifecycle drift and how would you detect it?

## AWS questions

1. Explain an Auto Scaling Group health check.
2. Difference between EC2 health checks and ELB health checks?
3. What happens if one app instance is terminated?
4. What happens if the NAT Gateway fails in this lab design?
5. Why is one NAT Gateway acceptable for a training lab but not ideal for production HA?
6. Why use security-group references instead of CIDR ranges between tiers?
7. Why is `publicly_accessible = false` important for RDS?
8. How does the EC2 application get the database password?
9. Why use Systems Manager instead of a bastion or SSH?

## Troubleshooting questions

### ALB returns 503. What do you check?
A strong troubleshooting path includes:

- target health
- health-check path/port
- app process status
- application listener port
- ALB-to-app security group flow
- user-data/bootstrap logs

### `/health` works but `/db` fails. What does that tell you?
The web process is alive, but a dependency-specific path is failing. Focus on database DNS, security groups, credentials/IAM, database status, SSL requirements, and application logs rather than immediately blaming the ALB.

### An instance is running but not registered as healthy. Why?
“Running” describes the EC2 VM lifecycle; it does not prove the application is serving the expected endpoint on the expected port.

## STAR practice scenarios

Prepare a 2-minute STAR answer for each:

1. **Availability:** An EC2 application instance failed and Auto Scaling replaced it.
2. **Networking:** The application could not reach RDS because of a security-group rule.
3. **IAM:** Application calls failed because the role lost permission to retrieve the secret.
4. **Deployment:** User data failed because a private subnet lost NAT connectivity.
5. **Collaboration:** Two engineers attempted Terraform changes simultaneously and remote state locking prevented conflicting writes.

For each answer include the symptom, evidence, root cause, exact change made, validation, and prevention.
