---
name: ecr-image-release
description: "Build, tag, scan, and publish the ToDoAI container image to Amazon ECR, then connect the image tag to Terraform deployment. Use for Docker builds, ECR login/push, image updates, or application releases in this AWS project."
---

# ToDoAI image release to ECR

## Locate and verify the source

1. The application source and Dockerfile are not in this workspace; the README identifies a separate ToDoAI source repository. Confirm the user's actual source checkout and build context before running Docker. Never assume the Terraform repository root is a valid Docker context.
2. Inspect the Dockerfile and application configuration. This deployment expects the app to listen on the configured port (currently 5173), bind to a container-reachable address, and serve the ALB health-check path `/`.
3. Build for the architecture used by the launch template (currently Amazon Linux 2023 x86_64). Report build or test failures rather than publishing an unverified image.

## Publish safely

1. Read the AWS region and ECR repository name from the current Terraform variables/configuration. Verify the AWS identity and that the expected repository exists; do not hardcode the account ID from old logs or README output.
2. Prefer a unique, traceable image tag (for example a commit SHA) over overwriting `v1`. Keep credentials out of command history and logs; use the AWS CLI ECR login-password flow piped directly to Docker login and never print or store the token.
3. Build, tag, push, and, where available, verify the pushed digest and image scan findings. Do not claim success based only on a local Docker image.
4. Pass the chosen tag to Terraform using the project's `image_tag` input. Avoid committing credentials or local `tfvars` files.

## Rollout behavior to account for

- EC2 user data pulls the configured image when an instance boots. Existing instances do not automatically pull a newly pushed image merely because a tag was overwritten.
- The ASG launch template uses its latest version, but changing a launch template or image tag does not itself guarantee that running instances are replaced. Inspect the Terraform plan and use an explicitly requested, controlled instance refresh or replacement strategy.
- Prefer immutable tags so the Terraform input, instance boot, and ECR digest identify the same release. Verify target health and the served application after rollout.
- Publishing an image is an external side effect. Push only when the user asked to publish/deploy, not just when asked to inspect or prepare a release.