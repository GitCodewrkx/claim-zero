# CLAIM ZERO4 — Day 3
## Pipeline

**Windows (PowerShell)** · Region **`us-east-1`** · Pipeline **`claim-zero-pipeline`**

This is **Day 3** of Claim Zero. Day 2 left the app live on ECS. Today you connect **GitHub** so a `git push` rebuilds the image and updates the **same** URL. Destroy in Lab **4.6**.

```text
  [Day 2: Live URL]──►[4 Pipeline]
     http://PUBLIC_IP     GitHub → CodePipeline → CodeBuild → ECR → ECS
```

**Start here:** **Before you start**, then Stage **4**. Stop after Lab **4.6**.

---

# Before you start

Today’s job is CI/CD: **GitHub `main`** triggers **CodePipeline**, **CodeBuild** builds and pushes **`claim-zero:latest`** to ECR, **ECS** deploys. The public URL does not change.

You will:

1. Confirm Day 2 is still live (`terraform output app_url`, ECS Running = 1).
2. Install Git if missing.
3. Change the Dockerfile so CodeBuild pulls base images from **Amazon ECR Public** (not Docker Hub).
4. Create `.gitignore` and `buildspec.yml`, push to GitHub, add `pipeline.tf`.
5. Handshake the GitHub connection, **Release change** after it is Available, prove a push updates the page, then **destroy**.

**You need today**

- Day 2 finished and **not** destroyed: `terraform/main.tf`, stack applied, **`http://PUBLIC_IP`** still loads
- AWS CLI still configured (`aws sts get-caller-identity` works)
- Terraform **1.5** or newer (same install as Day 2)
- Docker Desktop **running** (only needed if you rebuild locally; CodeBuild builds in AWS)
- Git for Windows and a **GitHub** account (Lab **4.0**)

**You do not need today:** Node.js, a Docker Hub account, a new AWS account, a new ECR repo.

CodeBuild has **no Docker Hub login**. If you leave Day 1’s `FROM node:22-alpine` / `FROM nginx:alpine`, the Build stage fails with **`429 Too Many Requests`**. Lab **4.1** switches those two lines to Amazon ECR Public before you push.

**Directories**

- Project root = the folder that contains `package.json` (the prompt ends with `\claim-zero>`).
- Git is created in the **project root**. Never run `git init` inside `terraform`.
- `cd terraform` goes into Terraform. If the prompt already ends with `\terraform>`, do **not** run `cd terraform` again.
- `cd ..` goes up one folder.

**Ctrl + C**

If a command occupies the terminal, click in the terminal and press **Ctrl + C**. If you see `Terminate batch job (Y/N)?`, type `Y` → **Enter**.

After any installer, close **all** terminals and the editor, then open them again.

---

## Confirm Day 2 is still live

1. Open the project folder (**File → Open Folder…** → folder with `package.json`).
2. **Terminal → New Terminal**.
3. If you are in the project root, run:

```bash
cd terraform
```

4. Run:

```bash
terraform output app_url
```

5. Open that **`http://PUBLIC_IP`** URL. Confirm the landing page.
6. AWS Console → **`us-east-1`** → **Amazon ECS** → **Clusters** → **`claim-zero-cluster`** → **Services** → **`claim-zero-service`**.
7. Confirm **Running tasks = 1**.

If the URL is dead or Running = 0, finish Day 2 Lab **3.4** / **3.5** before Stage 4.

---

## Install Git for Windows

1. Click **Terminal → New Terminal**.
2. Type this. Press **Enter**:

```bash
git --version
```

3. If you see `git version 2.…`, skip to Stage **4**.
4. Open Edge or Chrome.
5. Go to https://git-scm.com/install/windows
6. Click the link to download the latest **x64** Git for Windows. Use **ARM64** only if this laptop is ARM.
7. Open **Downloads**. Double-click `Git-…-64-bit.exe`.
8. If Windows asks **Do you want to allow this app**, click **Yes**.
9. Click **Next** on the licence screen.
10. Leave the install folder as default → **Next**.
11. Leave the selected components as default → **Next**.
12. Leave the Start Menu folder as default → **Next**.
13. On **Choosing the default editor used by Git**, pick **Use Visual Studio Code as Git's default editor** if VS Code is installed. Otherwise leave the default → **Next**.
14. On **Adjusting the name of the initial branch**, select **Override the default branch name** and type `main` → **Next**.
15. On **Adjusting your PATH environment**, select **Git from the command line and also from 3rd-party software** → **Next**.
16. Click **Next** on the remaining screens until **Install**. Wait.
17. Click **Finish**.
18. Kill the terminal. Click **Terminal → New Terminal**.
19. Type this. Press **Enter**:

```bash
git --version
```

20. **Pass:** `git version 2.` followed by numbers.

**Stop here until:** Day 2 URL loads, ECS Running = 1, `git --version` works.

---

# STAGE 4 — GitHub CI/CD

Connect GitHub so a `git push` updates the same Stage 3 URL. Destroy in Lab **4.6**.

---

## Lab 4.0 — GitHub account and Stage 4 prerequisites

Confirm the live URL, install Git, and write down one GitHub **username** (the owner). The repository **name** later is `claim-zero`. Do not create a repository yet.

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
8. Write the username from the top-right avatar. This is the **owner**. It is not the repository name.

```text
My Stage 4 GitHub username (owner): ________________
Repository name (always): claim-zero
terraform.tfvars later: OWNER/claim-zero
```

9. If `git commit` later says **Please tell me who you are**, run these two commands first (use your name and the email on the GitHub account):

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

10. Stop. Do not create a repository. Do not install AWS Connector.

---

## Lab 4.1 — Dockerfile for CodeBuild, `.gitignore`, and `buildspec.yml`

CodeBuild runs `docker build` in AWS. It cannot use your laptop’s Docker Hub login, so Day 1’s Docker Hub `FROM` lines fail there. Change the Dockerfile first, then add **`.gitignore`** and **`buildspec.yml`** in the project root.

**Steps**

1. Look at the prompt. It must end with `\claim-zero>`, not `\claim-zero\terraform>`. If it ends with `\terraform>`, run `cd ..`.
2. Open `Dockerfile` in the project root.
3. Replace **only** the two `FROM` lines. The rest of the file stays as Day 1.

Change this:

```dockerfile
FROM node:22-alpine AS builder
```

to this:

```dockerfile
FROM public.ecr.aws/docker/library/node:22-alpine AS builder
```

Change this:

```dockerfile
FROM nginx:alpine
```

to this:

```dockerfile
FROM public.ecr.aws/docker/library/nginx:alpine
```

4. The saved `Dockerfile` must look like this:

```dockerfile
FROM public.ecr.aws/docker/library/node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

FROM public.ecr.aws/docker/library/nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

5. Press **Ctrl + S**.
6. Confirm neither `FROM` line is still `node:22-alpine` or `nginx:alpine` without `public.ecr.aws`.
7. Project root → **New File** → `.gitignore`.
8. Paste the block below.
9. Press **Ctrl + S**.

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

10. Project root → **New File** → `buildspec.yml`.
11. Paste the block below.
12. Press **Ctrl + S**.

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

**Stop here until:** `Dockerfile` uses `public.ecr.aws` on both `FROM` lines, and `.gitignore` plus `buildspec.yml` are in the project root.

---

## Lab 4.2 — Create a GitHub repository and push

Create an **empty** GitHub repo as the Lab **4.0** user and push **`main`** from the **project root**.

**Steps**

1. Confirm the browser avatar matches the username from Lab **4.0**.
2. Open [https://github.com/YOUR_GITHUB_USERNAME/claim-zero](https://github.com/YOUR_GITHUB_USERNAME/claim-zero). If that page already exists from an earlier attempt, open **Settings** → **Danger zone** → **Delete this repository**. Type `YOUR_GITHUB_USERNAME/claim-zero` → delete it. Then continue.
3. Open [https://github.com/new](https://github.com/new).
4. Set the repository **name** to `claim-zero` (not your username).
5. Do **not** add a README, `.gitignore`, or license. The repo must be empty so `git push` can create `main`.
6. Click **Create repository**.
7. Write the owner from the URL `https://github.com/USERNAME/claim-zero`. That `USERNAME` is what you put in `terraform.tfvars` later.

```text
Owner (from the URL): ________________
github_full_repo = "OWNER/claim-zero"
```

8. In the terminal, go to the **project root** (the folder with `package.json`). If you are in `terraform`, run `cd ..`.
9. Confirm the prompt ends with `\claim-zero>`. Run:

```bash
dir package.json
dir terraform
```

10. Both must exist. If `dir package.json` fails, you are in the wrong folder.
11. If a Git repo was created **inside** `terraform` by mistake, delete **only** that nested repo. In File Explorer, open `terraform`. If you see a `.git` folder, delete that `.git` folder. Do not delete `terraform/main.tf`.
12. Run these in the **project root**:

```bash
git init
git remote -v
```

13. `git remote -v` should print nothing yet (no `origin`).
14. Run:

```bash
git branch -M main
git add .
git status
```

15. `git status` must list `Dockerfile`, `buildspec.yml`, `src/`, and `terraform/main.tf`. It must **not** list `terraform.tfstate`, `.terraform/`, or `terraform.tfvars`.
16. Run this command on one line:

```bash
git commit -m "Claim Zero source for CodePipeline"
```

17. If Git asks who you are, run the two `git config --global` commands from Lab **4.0**, then run the commit command again.
18. Replace `YOUR_GITHUB_USERNAME` with the owner from step 7. Run:

```bash
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/claim-zero.git
git push -u origin main
```

19. If `remote origin already exists`, run `git remote remove origin`, then run step 18 again.
20. Sign in as the **same** GitHub user if a browser window opens.
21. Refresh `https://github.com/YOUR_GITHUB_USERNAME/claim-zero`.
22. Confirm `Dockerfile`, `buildspec.yml`, and `src/` are on **`main`**.
23. Open `Dockerfile` on GitHub. Both `FROM` lines must start with `public.ecr.aws/docker/library/`.

---

## Lab 4.3 — Author the pipeline Terraform and allow a rolling replace

Add rolling-replace lines to the ECS service, then create `pipeline.tf` and `terraform.tfvars`.

**Steps**

1. Open `terraform/main.tf`.
2. Find `resource "aws_ecs_service" "app"`.
3. After the `launch_type = "EC2"` line, add these two settings if they are not already there:

```hcl
  # Host port 80 can only be used by one task on this instance.
  # 0% min healthy lets ECS stop the old task before starting the new one.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
```

Without those two lines, Deploy fails later because the EC2 host can bind port **80** to only one task at a time.

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
9. Replace `YOUR_GITHUB_USERNAME` with the Lab **4.2** **owner** (the GitHub username, not the word `claim-zero` alone):

```hcl
github_full_repo = "YOUR_GITHUB_USERNAME/claim-zero"
```

Example if the GitHub URL is `https://github.com/GitCodewrkx/claim-zero`:

```hcl
github_full_repo = "GitCodewrkx/claim-zero"
```

10. Press **Ctrl + S**.
11. Confirm there is a `/` in the value. `github_full_repo = "GitCodewrkx"` is wrong and Source will fail.

---

## Lab 4.4 — Apply, handshake, then Release change

Apply the pipeline. Terraform creates the GitHub connection as **Pending**. The first pipeline run **fails at Source** until you finish the handshake. That is expected. Do not skip **Release change** after the connection is **Available**.

**Steps**

1. If the prompt does not already end with `\terraform>`, run:

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

4. If Terraform asks for `var.github_full_repo`, you are missing `terraform/terraform.tfvars` or you are not in the `terraform` folder. Fix that, then plan again.
5. Confirm the plan includes `aws_codepipeline.claim` and `BUILD_GENERAL1_SMALL`.
6. Confirm the plan does **not** include an ALB, Fargate, or NAT Gateway.
7. Run:

```bash
terraform apply
```

8. Type `yes` and press **Enter**.
9. Wait for **`Apply complete!`**.
10. Sign into GitHub as the Lab **4.2** user. Stay signed in.
11. Open the AWS Console in **`us-east-1`** as the same AWS account that ran Terraform.
12. Search **Connections** (Developer Tools / CodePipeline settings) → open **`claim-zero-github`**.
13. Confirm status is **Pending**.
14. Click **Update pending connection**.
15. Click **Install a new app**. If this GitHub user already has **AWS Connector for GitHub**, select that app instead of installing a second copy.
16. When GitHub asks which repositories, choose **Only select repositories** → tick **`claim-zero`** → **Install** / **Connect**.
17. If GitHub asks you to sign in, use the **same** user as Lab **4.2**. A different GitHub user cannot see `OWNER/claim-zero`.
18. Return to the connection page. Click refresh until status is **Available**. Do not continue while it still says **Pending**.
19. Open **CodePipeline** → **Pipelines** → **`claim-zero-pipeline`**.
20. The run that started right after `terraform apply` is usually **Failed** at **Source**. That happened because the connection was still Pending. Click **Release change** → **Release**.
21. Open that new execution. Wait until Source, Build, and Deploy are all **Succeeded**. Build often takes **5–10 minutes**. Local Docker Desktop can be stopped; CodeBuild does not use it.
22. Open **Amazon ECS** → **`claim-zero-cluster`** → **`claim-zero-service`**.
23. Confirm **Running tasks = 1**.
24. Refresh **`http://PUBLIC_IP`**.

**If Source stays Failed after Available**

- `terraform.tfvars` must be `OWNER/claim-zero` with the same owner as the GitHub URL.
- AWS Connector must be installed on that same GitHub user, with access to repository **`claim-zero`**.
- The branch on GitHub must be **`main`**.

**If Build fails with `429 Too Many Requests`**

- CodeBuild is still pulling `node:22-alpine` or `nginx:alpine` from Docker Hub.
- Open `Dockerfile` on GitHub `main`. Both `FROM` lines must start with `public.ecr.aws/docker/library/`.
- If they do not, fix Lab **4.1**, then from the project root:

```bash
git add Dockerfile
git commit -m "Use ECR Public base images for CodeBuild"
git push origin main
```

- Wait for the new pipeline execution. Do not “fix” this by starting Docker Desktop on the laptop.

**If Deploy fails about port 80**

- Lab **4.3** rolling-replace lines are missing from `aws_ecs_service.app`. Add them, then from `terraform` run `terraform apply` again.

**If `terraform apply` says the pipeline, connection, or IAM role already exists**

- A previous Stage 4 attempt left leftovers. Tell the instructor before creating a second set of names.

**Stop here until:** connection **Available**, latest pipeline execution **Succeeded**, Running tasks = 1.

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

7. Confirm `origin` points at `https://github.com/YOUR_GITHUB_USERNAME/claim-zero.git`.
8. Run these commands on one line each:

```bash
git add src/App.jsx
git commit -m "Visible proof for CodePipeline"
git push origin main
```

9. On GitHub **`main`**, open `src/App.jsx` and confirm the new sentence.
10. Open **CodePipeline** → **Pipelines** → **`claim-zero-pipeline`**.
11. A new execution should start after the push. If nothing new appears after one minute, confirm you pushed **`main`** (not another branch) and that the connection is still **Available**.
12. Open the new execution. Wait until it is **Succeeded** (Build can take several minutes).
13. Open **`http://PUBLIC_IP`**.
14. Press **Ctrl + F5** (hard refresh so the browser does not keep the old page).
15. Confirm the new tagline.

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

**Day 3 is done when:** a GitHub push updated the live page, then destroy finished and the EC2 instance is **terminated**.
