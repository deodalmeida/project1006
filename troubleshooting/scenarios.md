# Troubleshooting Challenges — No Solutions Included

Treat each challenge like a production incident. Do not change random resources until the symptom disappears.

For every incident, submit:

1. Symptom and impact
2. Your first three checks and why
3. Commands/logs/evidence collected
4. Root cause
5. Fix
6. Validation after the fix
7. One prevention or monitoring improvement

## Challenge 1 — ALB returns 503

Your application instances appear to be running, but requests through the ALB return HTTP 503 and the targets are unhealthy.

**Instructor setup:** introduce a mismatch involving the load balancer health-check configuration and the application.

Useful evidence may include target health, application service status, local HTTP tests and application logs.

**Student goal:** identify why a running EC2 instance is not considered a healthy application target.

## Challenge 2 — Application works, database endpoint fails

`/health` and `/` work, but `/db` times out.

**Instructor setup:** introduce a network-path problem between the application tier and PostgreSQL.

**Student goal:** isolate whether the failure is DNS, routing, security groups, database availability, credentials or application configuration. Prove the actual cause with evidence.

## Challenge 3 — AWS AccessDenied

The application remains healthy, but a database-related request fails and the application logs contain an AWS authorization error.

**Instructor setup:** remove one permission the EC2 workload requires.

**Student goal:** identify the calling identity, the denied action/resource, and repair the policy without granting broad administrative access.

## Challenge 4 — Replacement instances never become healthy

Existing instances may work, but newly launched ASG instances fail to become healthy targets.

**Instructor setup:** introduce a problem that prevents a fresh private instance from completing bootstrap.

**Student goal:** trace the lifecycle from EC2 launch → user data → application service → target registration → health check. Find the first failing step.

## Challenge 5 — Terraform state is locked

A Terraform write operation reports that the remote state is locked.

**Student goal:** determine whether the lock is legitimate or stale and explain the safe response. Do not force-unlock until you can justify it.

## Challenge 6 — An application instance disappears

An EC2 instance in the Auto Scaling Group is terminated unexpectedly.

**Student goal:** observe what the ALB and ASG do, measure recovery, and explain which components provide load balancing, health detection and replacement.

## Instructor rule

Do not tell the student the root cause during the first troubleshooting pass. Ask for evidence: target-health output, routes, SG rules, IAM error details, service status, logs, or Terraform state information. The student should be able to explain *why* the evidence supports the diagnosis.
