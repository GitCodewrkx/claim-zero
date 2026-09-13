# CLAIM ZERO1
## Package · Publish · Provision · Pipeline

Work in **`us-east-1`**. Names: **`claim-zero:latest`**, ECR **`claim-zero`**, cluster **`claim-zero-cluster`**, service **`claim-zero-service`**, pipeline **`claim-zero-pipeline`**.

Open the VS Code folder. Complete Stages **0 → 4** in order. Destroy only in Lab **4.6**.

---

# STAGE 0 — Local smoke check

Build and open the starter app locally.

---

## Lab 0.1 — Production build

Compile the starter app to **`dist/`**.

**Steps**

1. VS Code → **Terminal → New Terminal**.
2. Go to the **project root** (the folder with `package.json`). Use `cd ..` if you are too deep.
3. Run `npm install` if packages are missing.
4. Run:

```bash
npm run build
```

5. Wait for the prompt.

---

## Lab 0.2 — Development server

Open the landing page locally, then stop the server.

**Steps**

1. Stay in the **project root**.
2. Run:

```bash
npm run dev
```

3. Open the URL shown in the terminal (usually **`http://localhost:5173`**).
4. Confirm the landing page.
5. Click the terminal → **Ctrl + C** → wait for the prompt.

---

# STAGE 1 — Package (Docker)

Build **`claim-zero:latest`** and open it at **`http://localhost:8080`**.

---

## Lab 1.1 — Confirm Docker Engine readiness

Start Docker before any `docker` command.

**Steps**

1. Open **Docker Desktop**.
2. Wait until the engine status is **running**.

---

## Lab 1.2 — Create `Dockerfile`

Create **`Dockerfile`** in the project root and paste the recipe.

**Steps**

1. Project root → **New File** → `Dockerfile`.
2. Paste the block below.
3. Press **Ctrl + S**.

```dockerfile
# ----- Stage 1: compile the React application into static files (dist/) -----
# node:22-alpine = small Linux Node image used ONLY for building (not the final runtime).
# Alpine keeps the builder small; the compiled files are copied out in Stage 2.
FROM node:22-alpine AS builder

# Working directory inside the build container. Later COPY/RUN paths are relative to /app.
WORKDIR /app

# Copy dependency manifests first to leverage Docker layer caching.
# If package.json does not change, Docker can reuse the npm install layer.
COPY package*.json ./

# Install dependencies required to compile the application.
RUN npm install

# Copy the full application source into the build context.
# .dockerignore (Lab 1.3) keeps node_modules, dist, and docs out of this copy.
COPY . .

# Produce optimised static assets in /app/dist (HTML/CSS/JS).
# This is the same production build you already proved locally in Stage 0.
RUN npm run build

# ----- Stage 2: serve the compiled assets with nginx -----
# Fresh slim image — no Node, no npm, only a web server.
# Everything above the second FROM is discarded except what you COPY --from=builder.
FROM nginx:alpine

# Replace default nginx web root with the Vite build output from the builder stage.
COPY --from=builder /app/dist /usr/share/nginx/html

# Document that the container listens on HTTP port 80.
# Lab 1.5 maps laptop port 8080 to this container port 80.
EXPOSE 80

# Start nginx in the foreground (required for containers — no background daemon).
CMD ["nginx", "-g", "daemon off;"]
```

---

## Lab 1.3 — Create `.dockerignore`

Create **`.dockerignore`** in the project root.

**Steps**

1. Project root → **New File** → `.dockerignore`.
2. Paste the block below.
3. Press **Ctrl + S**.

```text
# Dependencies are installed inside the image (do not copy the laptop's node_modules).
node_modules

# Build output is produced inside the image (Lab 1.2 RUN npm run build).
dist

# VCS metadata is not required in the build context.
.git
.gitignore

Dockerfile

# Documentation and local tooling should not bloat the context.
# terraform/ is authored in Stage 3 and is not part of the React image.
README.md
terraform
CLAIM_ZERO1_Instructions.md
*.md
.oxlintrc.json
```

---

## Lab 1.4 — Build the image

Build **`claim-zero:latest`** from the project root.

**Steps**

1. Go to the folder that contains `Dockerfile` and `package.json`. Use `cd ..` if you are too deep.
2. Press **Ctrl + C** if `npm run dev` is still running.
3. Run:

```bash
docker build -t claim-zero:latest .
```

4. Wait until the build finishes.

---

## Lab 1.5 — Run a local verification container

Open the image at **`http://localhost:8080`**.

**Steps**

1. Stay in the **project root**.
2. Run:

```bash
docker run -d -p 8080:80 --name claim-zero-container claim-zero:latest
```

3. Open **`http://localhost:8080`**.
4. Confirm the landing page.

---

## Lab 1.6 — Remove the local test container

Stop and remove the test container. Keep the image.

**Steps**

1. Run:

```bash
docker stop claim-zero-container
```

2. Run:

```bash
docker rm claim-zero-container
```

---

# STAGE 2 — Publish (ECR)

Put **`claim-zero:latest`** in Amazon ECR in **`us-east-1`**.

---

## Lab 2.1 — Create an IAM user

Create user **`claim-zero-participant`** and download an access-key CSV.

**Steps**

1. Open the AWS Console in **`us-east-1`**.
2. Open **IAM** → **Users** → **Create user**.
3. Name the user `claim-zero-participant`.
4. Choose **Attach policies directly**.
5. Select **AdministratorAccess** and **PowerUserAccess**.
6. Create the user.
7. Open the user → **Security credentials** → **Create access key**.
8. Select **Command Line Interface (CLI)**.
9. Confirm, then create the key.
10. Download the `.csv`.

---

## Lab 2.2 — Configure the AWS CLI

Store keys, region **`us-east-1`**, and output **`json`**.

**Steps**

1. Press **Ctrl + C** if another command is occupying the terminal.
2. Run:

```bash
aws configure
```

3. Enter **AWS Access Key ID** → **Enter**.
4. Enter **AWS Secret Access Key** → **Enter**.
5. Enter `us-east-1` → **Enter**.
6. Enter `json` → **Enter**.
7. Run:

```bash
aws sts get-caller-identity
```

---

## Lab 2.3 — Create the ECR repository

Create the ECR repository **`claim-zero`**.

**Steps**

1. Run:

```bash
aws ecr create-repository --repository-name claim-zero --region us-east-1
```

---

## Lab 2.4 — Resolve account ID

Copy your 12-digit AWS account ID.

**Steps**

1. Run:

```bash
aws sts get-caller-identity --query Account --output text
```

2. Copy the printed **`ACCOUNT_ID`**.

---

## Lab 2.5 — Authenticate Docker to ECR

Log Docker into ECR.

**Steps**

1. Replace `ACCOUNT_ID` with the value from Lab **2.4**.
2. Run:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

---

## Lab 2.6 — Tag and push the image

Tag the local image and push **`latest`** to ECR.

**Steps**

1. Replace `ACCOUNT_ID` with the value from Lab **2.4**.
2. Run:

```bash
docker tag claim-zero:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/claim-zero:latest
```

3. Run:

```bash
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/claim-zero:latest
```

4. Wait until the push finishes.

---

## Lab 2.7 — Confirm in the AWS Console

Confirm tag **`latest`** in ECR.

**Steps**

1. Open **Elastic Container Registry**.
2. Set Region to **`us-east-1`**.
3. Open **Repositories** → **claim-zero**.
4. Confirm tag **latest**.

---

# STAGE 3 — Provision + live URL

Apply the Terraform stack and open **`http://PUBLIC_IP`**. Do not destroy at the end of this stage.

---

## Lab 3.1 — Create `terraform/main.tf`

Create `terraform/main.tf` and paste the full stack.

**Steps**

1. Project root → **New Folder** → `terraform`.
2. Inside `terraform` → **New File** → `main.tf`.
3. Paste the entire block below.
4. Press **Ctrl + S**.

```hcl
# =============================================================================
# CLAIM ZERO — Free Tier ECS on EC2
# Region: us-east-1
# No ALB / Fargate in this edition. Destroy at session end.
# Paste this entire file into terraform/main.tf (Lab 3.1). Do not split it.
# =============================================================================

# Terraform settings: minimum Terraform version + AWS provider pin.
# "~> 5.0" means "any 5.x" — avoids accidental jumps to a new major provider.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Every resource below is created in this region (must match ECR: us-east-1).
provider "aws" {
  region = "us-east-1"
}

# Look up the account currently authenticated via the AWS CLI / credentials.
# Used to build the ECR image URI without hard-coding your account ID.
data "aws_caller_identity" "current" {}

# Reuse the account's default VPC — no custom networking cost for this lab.
data "aws_vpc" "default" {
  default = true
}

# Discover subnets that belong to that default VPC.
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# AWS publishes the recommended ECS-optimised AMI ID in SSM Parameter Store.
# This keeps the lab on a current Amazon Linux 2 ECS AMI without hard-coding.
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

locals {
  project    = "claim-zero"
  account_id = data.aws_caller_identity.current.account_id
  region     = "us-east-1"
  # Must already exist in ECR from Stage 2 of this course.
  # Shape: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/claim-zero:latest
  image_uri  = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.project}:latest"
  # Pick the first default subnet for the single EC2 host.
  subnet_id  = element(data.aws_subnets.default.ids, 0)
}

# -----------------------------------------------------------------------------
# Networking — allow inbound HTTP (port 80) from the internet to the EC2 host.
# -----------------------------------------------------------------------------
resource "aws_security_group" "ecs" {
  name        = "${local.project}-sg"
  description = "Allow HTTP for CLAIM ZERO Free Tier lab"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Workshop: open HTTP. Tighten in production.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # All outbound (needed for ECR pulls, logs, etc.)
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.project}-sg"
    Project = local.project
  }
}

# Logical grouping for ECS services/tasks.
resource "aws_ecs_cluster" "claim" {
  name = "${local.project}-cluster"

  tags = {
    Name    = "${local.project}-cluster"
    Project = local.project
  }
}

# -----------------------------------------------------------------------------
# IAM — EC2 instance role so the ECS agent can register with the cluster.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_instance" {
  name = "${local.project}-ecs-instance-role"

  # Trust policy: only the EC2 service may assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  # AWS managed policy that grants ECS agent permissions on the instance.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Instance profiles are how EC2 instances receive an IAM role.
resource "aws_iam_instance_profile" "ecs" {
  name = "${local.project}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

# -----------------------------------------------------------------------------
# IAM — task execution role so ECS can pull from ECR and write CloudWatch logs.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_execution" {
  name = "${local.project}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Short retention keeps log cost tiny for a workshop.
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.project}"
  retention_in_days = 3

  tags = {
    Project = local.project
  }
}

# -----------------------------------------------------------------------------
# Compute — one Free Tier–eligible EC2 host joined to the ECS cluster.
# -----------------------------------------------------------------------------
resource "aws_instance" "ecs" {
  ami                         = data.aws_ssm_parameter.ecs_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.ecs.id]
  iam_instance_profile        = aws_iam_instance_profile.ecs.name
  # Needed so you can browse http://PUBLIC_IP at the end of Stage 3.
  associate_public_ip_address = true

  # On first boot, tell the ECS agent which cluster to join.
  user_data = base64encode(<<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.claim.name} >> /etc/ecs/ecs.config
  EOT
  )

  tags = {
    Name    = "${local.project}-ecs-instance"
    Project = local.project
  }
}

# -----------------------------------------------------------------------------
# ECS task definition — "what container to run" (image, ports, logs, size).
# -----------------------------------------------------------------------------
resource "aws_ecs_task_definition" "app" {
  family                   = local.project
  requires_compatibilities = ["EC2"]   # Not Fargate in this course
  network_mode             = "bridge"  # Classic Docker bridge on the EC2 host
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = local.project
      image     = local.image_uri # ECR URI from Stage 2
      essential = true
      portMappings = [
        {
          containerPort = 80 # nginx inside the container
          hostPort      = 80 # exposed on the EC2 public IP
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# -----------------------------------------------------------------------------
# ECS service — keep desired_count tasks running on the cluster.
# -----------------------------------------------------------------------------
resource "aws_ecs_service" "app" {
  name            = "${local.project}-service"
  cluster         = aws_ecs_cluster.claim.id
  task_definition = aws_ecs_task_definition.app.arn
  # Keep exactly one task running (enough for this lab).
  desired_count   = 1
  launch_type     = "EC2"

  # Wait for the EC2 instance resource to exist before creating the service.
  depends_on = [aws_instance.ecs]
}

# -----------------------------------------------------------------------------
# Outputs — values you need to open the live site at the end of Stage 3.
# -----------------------------------------------------------------------------
output "app_url" {
  description = "Browser URL once the ECS task is RUNNING"
  value       = "http://${aws_instance.ecs.public_ip}"
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.claim.name
}

output "ecr_image_uri" {
  value = local.image_uri
}

output "instance_public_ip" {
  value = aws_instance.ecs.public_ip
}
```

---

## Lab 3.2 — Initialise and validate

Initialise Terraform and validate `main.tf`.

**Steps**

1. Run:

```bash
cd terraform
```

2. Run:

```bash
terraform init
```

3. Run:

```bash
terraform validate
```

---

## Lab 3.3 — Review the execution plan

Preview what Terraform will create.

**Steps**

1. Stay in the `terraform` folder.
2. Run:

```bash
terraform plan
```

3. Confirm the plan includes **`t3.micro`** and ECS on **EC2**.
4. Confirm the plan does **not** include an Application Load Balancer.

---

## Lab 3.4 — Apply the configuration

Create the stack and copy **`app_url`**. Do not destroy.

**Steps**

1. Stay in the `terraform` folder.
2. Run:

```bash
terraform apply
```

3. Type `yes` and press **Enter**.
4. Wait for **`Apply complete!`**.
5. Run:

```bash
terraform output
```

6. Copy **`app_url`**.

---

## Lab 3.5 — Confirm the service and open the URL

Wait for **Running = 1**, then open **`http://PUBLIC_IP`**.

**Steps**

1. Open **Amazon ECS** in **`us-east-1`**.
2. Open **Clusters** → **`claim-zero-cluster`**.
3. Open **Services** → **`claim-zero-service`**.
4. Wait until **Running tasks = 1**.
5. Confirm launch type **EC2**.
6. Stay in (or return to) the `terraform` folder.
7. Run:

```bash
terraform output app_url
```

8. Open that URL in a new tab. Use **`http://`** only.
9. Confirm the landing page.

---

# STAGE 4 — GitHub CI/CD

Connect GitHub so a `git push` updates the same Stage 3 URL. Destroy in Lab **4.6**.

---

## Lab 4.0 — GitHub account and Stage 4 prerequisites

Confirm the live URL, install Git, and write down one GitHub username. Do not create a repository yet.

**Steps**

1. In the `terraform` folder, run:

```bash
terraform output app_url
```

2. Open that **`http://PUBLIC_IP`** URL.
3. Confirm ECS **Running tasks = 1**.
4. Run:

```bash
git --version
```

5. If Git is missing, install [Git for Windows](https://git-scm.com/download/win), open a new terminal, and run `git --version` again.
6. Open [https://github.com](https://github.com) in one browser.
7. **Sign up** or **Sign in**.
8. Write the username from the top-right avatar:

```text
My Stage 4 GitHub username: ________________
```

9. Stop. Do not create a repository. Do not install AWS Connector.

---

## Lab 4.1 — Author `.gitignore` and `buildspec.yml`

Create **`.gitignore`** and **`buildspec.yml`** in the project root.

**Steps**

1. Project root → **New File** → `.gitignore`.
2. Paste the block below.
3. Press **Ctrl + S**.

```text
# Laptop install — CodeBuild runs npm install inside Docker, not from this folder.
node_modules/

# Local Vite output — the image build produces dist/ inside Docker.
dist/

# Terraform working files — never commit state or the lock/plugin cache.
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl
crash.log

# Local variable values (your GitHub owner/repo). Keep them on the laptop.
*.tfvars
!*.tfvars.example
```

4. Project root → **New File** → `buildspec.yml`.
5. Paste the block below.
6. Press **Ctrl + S**.

```yaml
# CLAIM ZERO — CodeBuild recipe (Lab 4.1).
# This is Stage 2 on AWS: login to ECR, docker build, push claim-zero:latest.
# Keep it short. No tests, no second image, no docker compose.

version: 0.2

phases:
  pre_build:
    commands:
      - ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
      - REGION=us-east-1
      - REPO=claim-zero
      - IMAGE_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO:latest
      - echo Logging in to Amazon ECR
      - aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
  build:
    commands:
      - echo Build started on `date`
      - docker build -t $REPO:latest .
      - docker tag $REPO:latest $IMAGE_URI
  post_build:
    commands:
      - echo Pushing $IMAGE_URI
      - docker push $IMAGE_URI
      # Container name MUST match the task definition (claim-zero).
      - printf '[{"name":"claim-zero","imageUri":"%s"}]' $IMAGE_URI > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

---

## Lab 4.2 — Create a GitHub repository and push

Create an empty GitHub repo as the Lab **4.0** user and push **`main`**.

**Steps**

1. Confirm the browser avatar matches the username from Lab **4.0**.
2. Open [https://github.com/new](https://github.com/new).
3. Set the repository name to `claim-zero`.
4. Do **not** add a README, `.gitignore`, or license.
5. Click **Create repository**.
6. Write the owner from `https://github.com/USERNAME/claim-zero`.
7. In the terminal, go to the **project root** (the folder with `package.json`). If you are in `terraform`, run `cd ..`.
8. Run:

```bash
git init
git remote -v
```

9. Run:

```bash
git branch -M main
git add .
git status
```

10. Run this command on one line:

```bash
git commit -m "Claim Zero source for CodePipeline"
```

11. Replace `YOUR_GITHUB_USERNAME` with the owner from step 6. Run:

```bash
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/claim-zero.git
git push -u origin main
```

12. Sign in as the **same** GitHub user if a browser window opens.
13. Refresh `https://github.com/YOUR_GITHUB_USERNAME/claim-zero`.
14. Confirm `Dockerfile`, `buildspec.yml`, and `src/` are on **`main`**.

---

## Lab 4.3 — Author the pipeline Terraform and allow a rolling replace

Add rolling-replace lines to the ECS service, then create `pipeline.tf` and `terraform.tfvars`.

**Steps**

1. Open `terraform/main.tf`.
2. Find `resource "aws_ecs_service" "app"`.
3. After the `launch_type = "EC2"` line, add:

```hcl
  # Host port 80 can only be used by one task on this instance.
  # 0% min healthy lets ECS stop the old task before starting the new one.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
```

4. Press **Ctrl + S**.
5. In the `terraform` folder → **New File** → `pipeline.tf`.
6. Paste the entire block below.
7. Press **Ctrl + S**.

```hcl
# =============================================================================
# CLAIM ZERO — Free Tier CI/CD (Stage 4)
# One CodePipeline V1 + CodeBuild SMALL. No Fargate / ALB / NAT / V2.
# Paste this entire file into terraform/pipeline.tf (Lab 4.3).
# =============================================================================

# GitHub owner/repo from terraform.tfvars (Lab 4.3). Example: jane/claim-zero
variable "github_full_repo" {
  description = "GitHub owner/name for the claim-zero repository"
  type        = string
}

# -----------------------------------------------------------------------------
# GitHub connection — Terraform creates it as PENDING.
# You complete the handshake in the console (Lab 4.4) before Source can clone.
# -----------------------------------------------------------------------------
resource "aws_codestarconnections_connection" "github" {
  name          = "claim-zero-github"
  provider_type = "GitHub"
}

# -----------------------------------------------------------------------------
# Artifact bucket — CodePipeline V1 must store zipped source/build output.
# Account ID in the name keeps it globally unique. 1-day expiry. Private.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "artifacts" {
  bucket        = "claim-zero-artifacts-${local.account_id}"
  force_destroy = true

  tags = {
    Project = local.project
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "expire-artifacts-1-day"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 1
    }
  }
}

# -----------------------------------------------------------------------------
# ECR lifecycle on the existing Stage 2 repo — keep the private repo small.
# Destroy removes this policy only; the ECR repository itself stays.
# -----------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "claim" {
  repository = local.project

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 2 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 2
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Short retention for CodeBuild logs (workshop only).
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/codebuild/${local.project}"
  retention_in_days = 1

  tags = {
    Project = local.project
  }
}

# -----------------------------------------------------------------------------
# IAM — CodeBuild may login to ECR, push claim-zero:latest, write logs, read S3.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "codebuild" {
  name = "${local.project}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${local.project}-codebuild-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "arn:aws:ecr:${local.region}:${local.account_id}:repository/${local.project}"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CodeBuild — BUILD_GENERAL1_SMALL, privileged (docker build), NOT in a VPC.
# -----------------------------------------------------------------------------
resource "aws_codebuild_project" "claim" {
  name         = "${local.project}-build"
  description  = "CLAIM ZERO Free Tier docker build"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }

  tags = {
    Project = local.project
  }
}

# -----------------------------------------------------------------------------
# IAM — CodePipeline may use the GitHub connection, start CodeBuild, deploy ECS.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "codepipeline" {
  name = "${local.project}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${local.project}-codepipeline-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.claim.arn
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection",
          "codeconnections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = aws_iam_role.ecs_execution.arn
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = ["ecs-tasks.amazonaws.com"]
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# One V1 pipeline: Source (GitHub) → Build (SMALL) → Deploy (existing ECS).
# pipeline_type = "V1" is required — do not let this become V2.
# -----------------------------------------------------------------------------
resource "aws_codepipeline" "claim" {
  name          = "${local.project}-pipeline"
  pipeline_type = "V1"
  role_arn      = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = var.github_full_repo
        BranchName           = "main"
        DetectChanges        = "true"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.claim.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.claim.name
        ServiceName = aws_ecs_service.app.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = {
    Project = local.project
  }
}

output "pipeline_name" {
  value = aws_codepipeline.claim.name
}

output "github_connection_arn" {
  value = aws_codestarconnections_connection.github.arn
}
```

8. In the `terraform` folder → **New File** → `terraform.tfvars`.
9. Replace `YOUR_GITHUB_USERNAME` with the Lab **4.2** owner:

```hcl
github_full_repo = "YOUR_GITHUB_USERNAME/claim-zero"
```

10. Press **Ctrl + S**.

---

## Lab 4.4 — Apply, handshake, first pipeline run

Apply the pipeline, finish the GitHub handshake, and wait for one **Succeeded** run.

**Steps**

1. Run:

```bash
cd terraform
```

2. Run:

```bash
terraform init -upgrade
```

3. Run:

```bash
terraform plan
```

4. Confirm the plan includes `aws_codepipeline.claim` and `BUILD_GENERAL1_SMALL`.
5. Confirm the plan does **not** include an ALB, Fargate, or NAT Gateway.
6. Run:

```bash
terraform apply
```

7. Type `yes` and press **Enter**.
8. Wait for **`Apply complete!`**.
9. Sign into GitHub as the Lab **4.2** user.
10. Open the AWS Console in **`us-east-1`**.
11. Search **Connections** → open **`claim-zero-github`**.
12. Click **Update pending connection**.
13. Click **Install a new app** (or select **AWS Connector for GitHub** if this same user already has it).
14. Choose **Only select repositories** → select **`claim-zero`** → **Install** / **Connect**.
15. Wait until the connection status is **Available**.
16. Open **CodePipeline** → **Pipelines** → **`claim-zero-pipeline`**.
17. Wait until the latest execution is **Succeeded**.
18. Open **Amazon ECS** → **`claim-zero-cluster`** → **`claim-zero-service`**.
19. Confirm **Running tasks = 1**.
20. Refresh **`http://PUBLIC_IP`**.

---

## Lab 4.5 — Prove GitHub is the trigger

Change a visible sentence, push to **`main`**, and confirm the live page updates.

**Steps**

1. Go to the **project root**. If you are in `terraform`, run `cd ..`.
2. Open `src/App.jsx`.
3. Find the text in `<p className="tagline">`.
4. Change it to a new visible sentence, for example:

```text
Building the Next Generation of Cloud Engineers — shipped from GitHub.
```

5. Press **Ctrl + S**.
6. Run:

```bash
git remote -v
```

7. Run these commands on one line each:

```bash
git add src/App.jsx
git commit -m "Visible proof for CodePipeline"
git push origin main
```

8. On GitHub **`main`**, open `src/App.jsx` and confirm the new sentence.
9. Open **CodePipeline** → **Pipelines** → **`claim-zero-pipeline`**.
10. Open the new execution that starts after this push.
11. Wait until the execution is **Succeeded**.
12. Open **`http://PUBLIC_IP`**.
13. Press **Ctrl + F5**.
14. Confirm the new tagline.

---

## Lab 4.6 — Destroy the pipeline and the compute stack

Destroy the pipeline and the Stage 3 stack. Confirm the EC2 instance is **terminated**.

**Steps**

1. Run:

```bash
cd terraform
```

2. Run:

```bash
terraform destroy
```

3. Type `yes` and press **Enter**.
4. Wait until destroy finishes.
5. Open **EC2** → **Instances** in **`us-east-1`**.
6. Confirm the workshop instance is **terminated**.
7. Open **CodePipeline** and confirm **`claim-zero-pipeline`** is gone.
8. Open **Connections**. If **`claim-zero-github`** remains, delete it.
