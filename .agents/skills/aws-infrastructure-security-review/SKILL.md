---
name: aws-infrastructure-security-review
description: "Review this Terraform AWS project for cloud security risks and practical least-privilege improvements. Use for security audits, IAM or security-group review, public exposure, Terraform hardening, secrets, state, or deployment-safety questions."
---

# Security review for this AWS project

Perform a read-only review first. Ground each finding in the current Terraform/configuration and distinguish confirmed behavior from assumptions. Do not modify infrastructure or apply remediation unless asked.

## Review checklist

- **Network exposure:** inspect ALB listeners, security-group ingress/egress, subnet routing, and whether instances are directly reachable. Current design documents an internet-facing ALB on HTTP/80 and application-port access restricted to the ALB security group; verify the files before relying on this.
- **Transport security:** check for HTTPS listener, ACM certificate, redirect, and application-to-target protocol. If absent, clearly state that user traffic is unencrypted; propose HTTPS as a design improvement, not as an already-present feature.
- **IAM:** inspect instance role policies and deployment permissions for least privilege, especially ECR repository scope, `iam:PassRole`, Route53, and any request to attach broad managed policies. Do not recommend root or administrator access for routine operations.
- **Images and bootstrapping:** inspect ECR tag mutability/scanning, image provenance, user-data behavior, logging, and whether a deployment actually refreshes running instances. Do not expose tokens or sensitive user-data values.
- **Secrets and state:** inspect `.gitignore` and tracked files for state, plans, credentials, and non-example tfvars. Do not read out or publish secret/state contents. Recommend secure remote state with encryption and access controls before treating this as production-ready.
- **DNS and lifecycle:** identify public hosted-zone/registrar assumptions and destructive replacement risks. Separate Terraform-managed records from manual registrar delegation.

## Findings format

For each issue, provide severity, evidence (file and resource/block), impact, and a proportional remediation. Clearly label trade-offs and operational prerequisites. Avoid claiming compliance or production readiness from a brief repository review. Do not make network, IAM, DNS, or resource changes as a side effect of the review.