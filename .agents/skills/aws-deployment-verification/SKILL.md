---
name: aws-deployment-verification
description: "Diagnose and verify this project's AWS deployment across EC2 Auto Scaling, ALB target health, ECR image startup, and Route53 DNS. Use for deployment checks, HTTP failures, unhealthy targets, ASG status, DNS propagation, or post-deploy validation."
---

# Verify and troubleshoot the AWS deployment

Prefer read-only AWS CLI/API and HTTP/DNS checks. Confirm the active account and region first. Do not expose credentials, state contents, or unnecessary account/resource identifiers in reports.

## Check in dependency order

1. **Configuration and AWS identity:** inspect Terraform outputs/variables and confirm the intended AWS account and region. Do not infer the live values from stale README examples.
2. **Auto Scaling:** inspect ASG desired/min/max capacity, instance lifecycle and health status, and recent scaling activities. Distinguish an instance being `InService` from its ALB target being healthy.
3. **Target group and ALB:** inspect target health/reason codes, listener rules, security groups, and the health-check path/port. The current target group checks HTTP `/` on the application traffic port; ALB ingress is public HTTP port 80, and app ingress is intended to be limited to the ALB security group.
4. **Instance startup and image:** if a target is unhealthy, check launch-template/user-data status, Docker service/container state, ECR pull permissions, selected image tag/digest, and application bind port. The instance user data writes to `/var/log/todoai-userdata.log`; access logs only through an authorized mechanism (for example an existing SSM session or console workflow), and do not request private keys or credentials.
5. **Application and DNS:** request the ALB DNS name directly before testing the custom domain. Check Route53 alias configuration and public DNS NS/A answers separately. A Route53 hosted zone is not authoritative at the registrar until its nameservers are delegated there.
6. **Summarize:** report each check as verified, failed, or not checked, include relevant non-sensitive error/reason codes, and propose the smallest next diagnostic step.

## Known project-specific behavior

- The app is reached via HTTP in the current Terraform; there is no configured HTTPS listener or certificate. Do not report TLS as tested or working.
- Vite preview may reject an unfamiliar `Host` header. If direct ALB HTTP returns 403 with a Vite host-block message, verify the application `preview.allowedHosts` configuration in the separate source repository; do not weaken host validation indiscriminately.
- A mutable ECR tag being updated does not update already-running containers. Compare the instance's launch time and image release/digest, and verify that a rollout actually replaced instances.
- DNS propagation and registrar nameserver changes are external conditions. Never change registrar DNS or delete hosted zones as part of read-only troubleshooting.