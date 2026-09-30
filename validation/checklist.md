# Validation Checklist

Use this checklist after every deployment.

## Terraform

```bash
terraform fmt -check -recursive
terraform validate
terraform plan
```

- [ ] No unexpected destructive changes
- [ ] No secrets are present in Terraform outputs
- [ ] State backend is remote when using the team-style setup

## Networking

- [ ] VPC spans at least two Availability Zones
- [ ] ALB is in two public subnets
- [ ] Application instances are in private app subnets
- [ ] RDS is in private DB subnets
- [ ] RDS is not publicly accessible
- [ ] App SG accepts port 8000 only from ALB SG
- [ ] DB SG accepts port 5432 only from App SG
- [ ] No inbound SSH rule exists

## Application

```bash
URL=$(terraform output -raw application_url)
curl -fsS "$URL/health"
curl -fsS "$URL/"
curl -fsS "$URL/db"
```

- [ ] `/health` returns HTTP 200
- [ ] `/` returns a hostname
- [ ] Repeated requests show traffic can reach more than one instance
- [ ] `/db` returns `status: connected`
- [ ] Visit count increases

## Load balancer

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw target_group_arn)"
```

- [ ] At least two healthy targets

## Auto Scaling

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$(terraform output -raw autoscaling_group_name)"
```

- [ ] Desired capacity = 2
- [ ] Two instances are InService

## Systems Manager

- [ ] Instances appear as managed nodes in Systems Manager
- [ ] Session Manager connection succeeds without opening port 22

## Failure recovery

- [ ] Terminating one EC2 instance does not make the site unavailable for an extended period
- [ ] Auto Scaling launches a replacement
