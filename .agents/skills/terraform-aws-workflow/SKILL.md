---
name: terraform-aws-workflow
description: "Safely inspect, validate, plan, apply, or destroy this repository's AWS infrastructure with Terraform. Use for Terraform changes, terraform plan/apply/destroy, AWS provisioning, or state and provider issues in this ToDoAI project."
---

# Terraform workflow for this project

Use this skill when changing or operating the Terraform infrastructure in `Terraform/`.

## Project context

- Terraform configuration is in `Terraform/`; it provisions a default VPC deployment with an ALB, EC2 Auto Scaling Group, ECR image lookup, IAM instance profile, and Route53 hosted zone/alias.
- The provider defaults to `eu-north-1`. Check current variables and configuration rather than assuming defaults are unchanged.
- The ECR repository is expected to exist before Terraform runs.
- Terraform state, its backup, and plan files are local sensitive artifacts. Do not print their contents, commit them, or copy them into chat.
- The README describes AWS CLI use in WSL and Terraform on Windows. These environments may use different AWS credential files/profiles.

## Workflow

1. Inspect the requested Terraform files and current repository changes before editing. Preserve existing naming and variable conventions.
2. Before AWS operations, check that the intended AWS identity and region are selected. Use read-only identity/configuration checks; never ask the user to paste access keys, session tokens, or credential files.
3. From `Terraform/`, initialize when needed, format, validate, and create a plan. Review the plan for unintended resource replacement, public exposure, IAM changes, Route53 changes, and destructive actions.
4. Report material plan consequences before mutation. Run `apply` or `destroy` only when the user explicitly requested that operation; do not treat a successful plan as authorization.
5. After an apply, verify outputs and resource health using read-only checks. Do not claim a live deployment was verified unless checks were actually run.

Typical validation sequence (run in `Terraform/`): `terraform fmt -check -recursive`, `terraform init`, `terraform validate`, then `terraform plan`. Use a saved plan only when useful, keep it local, and inspect it before applying.

## Safety and project-specific notes

- Never add credentials, non-example `tfvars`, state, backups, or plan files to version control. Follow `.gitignore` and check `git status` before finishing.
- Do not recommend root or broad administrator policies as a routine fix. Explain the missing IAM action and prefer a least-privilege deployment role.
- Creating a Route53 hosted zone does not change registrar delegation. Nameserver changes at the registrar are a separate external action and require explicit user direction.
- The current ALB configuration is HTTP-only. Do not describe the endpoint as HTTPS or assume a certificate/listener exists.
- Terraform changes to the launch template do not by themselves prove that existing Auto Scaling instances have been replaced. Check the ASG instance-refresh/replacement plan and verify the serving target afterward.
- If credentials, account/region, or the target hosted zone are ambiguous, stop before mutation and clarify rather than operating on a guessed account.