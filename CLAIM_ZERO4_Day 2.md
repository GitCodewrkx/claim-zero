# CLAIM ZERO4 — Day 2
## Publish · Provision

**Windows (PowerShell)** · Region **`us-east-1`** · Image **`claim-zero:latest`** · ECR **`claim-zero`**

This is **Day 2** of Claim Zero. Day 1 packaged the app on your laptop. Today you **publish** the image to Amazon ECR and **provision** ECS on one EC2 host with Terraform, then open the live URL.

You do **not** use GitHub or CodePipeline today. Do **not** run `terraform destroy` at the end of this file.

```text
  [Day 1: Image]──►[2 Publish]──►[3 Provision]
     claim-zero:latest    Amazon ECR      ECS on EC2      http://PUBLIC_IP
```

**Start here:** **Before you start**, then Stage **2**, then Stage **3**. Stop after Lab **3.5**.

---

# Before you start

Today’s job is to put **`claim-zero:latest`** in **ECR**, then run it on AWS. Stay in **`us-east-1`**. Names: ECR repo **`claim-zero`**, cluster **`claim-zero-cluster`**, service **`claim-zero-service`**.

You will:

1. Confirm Day 1 is done (Docker running, image `claim-zero:latest` on the laptop).
2. Sign in to AWS and install the AWS CLI and Terraform.
3. Create an IAM user, push the image to ECR.
4. Create `terraform/main.tf`, apply, and open **`http://PUBLIC_IP`**.

**You need today**

- Day 1 finished: `Dockerfile`, image **`claim-zero:latest`**, Docker Desktop **running**
- Edge or Chrome, an email inbox, a phone that can receive SMS
- A debit or credit card (AWS will not finish sign-up without a payment method)
- AWS CLI v2 and Terraform **1.5** or newer (install below if missing)

**You do not need today:** Git, GitHub, Node.js, a Docker Hub account, CodePipeline.

**Directories**

- Project root = the folder that contains `package.json`
- `cd terraform` goes into Stage 3
- `cd ..` goes up one folder. Repeat `cd ..` if you are still in the wrong folder.

**Ctrl + C**

If a command occupies the terminal, click in the terminal and press **Ctrl + C**. If you see `Terminate batch job (Y/N)?`, type `Y` → **Enter**.

After any installer, close **all** terminals and the editor, then open them again.

---

## Confirm Day 1

1. Open **Docker Desktop**. Wait until it says **running**.
2. Open the project folder (**File → Open Folder…** → folder with `package.json`).
3. **Terminal → New Terminal**.
4. Type this. Press **Enter**:

```bash
docker images
```

5. Confirm a row **`claim-zero`** with tag **`latest`**. If it is missing, finish Day 1 Lab **1.4** first.
6. Type this. Press **Enter**:

```bash
dir Dockerfile
```

7. You must see `Dockerfile`. If **Cannot find path**, type `cd ..` → **Enter** and try again.

---

## Create an AWS account

Sign up as the **root** user. Do not create IAM users or access keys in this section.

1. Open Edge or Chrome.
2. Go to https://signin.aws.amazon.com/signup?request_type=register
3. If you already have an AWS account: click **Sign in to an existing AWS account**, then go to step 16.
4. Type the **root user email address**.
5. Type an **AWS account name** (example `first-last-claim-zero`).
6. Click **Verify email address**.
7. Open the email inbox. Copy the verification code.
8. Paste the code. Click **Verify**.
9. Type a root password. Confirm it. Click **Continue**.
10. Choose a plan if asked. Use the free / Free Tier option if it is shown.
11. Fill in contact details. Tick that you accept the **AWS Customer Agreement**. Continue.
12. Enter a valid payment method and billing address. AWS will not let you continue without a card. A small authorisation check can appear; it is reversed.
13. Choose country code. Type a phone number that can receive SMS. Click **Send SMS**. Enter the code. Continue.
14. For AWS Support, choose **Basic** (free) if listed. Click **Complete sign up**.
15. Wait for the activation email (usually minutes; can take up to 24 hours).
16. Go to https://console.aws.amazon.com/
17. Sign in as **Root user**.
18. At the top right, click the Region. Click **US East (N. Virginia)** / **`us-east-1`**.
19. Confirm the console home page loads.
20. Stop. Do not create IAM users, access keys, or an ECR repository yet. Lab **2.1** does that.

---

## Install the AWS CLI v2

This installs the `aws` command. Do **not** run `aws configure` yet. That is Lab **2.2**.

1. Click **Terminal → New Terminal**.
2. Type this. Press **Enter**:

```bash
aws --version
```

3. If you see `aws-cli/2.…`, skip to **Install Terraform**.
4. Type this. Press **Enter**:

```bash
irm https://awscli.amazonaws.com/v2/install.ps1 | iex
```

5. Wait until the prompt returns.
6. If that command failed: browser → https://awscli.amazonaws.com/AWSCLIV2.msi → open the download → **Next** until **Finish**.
7. Kill the terminal. Click **Terminal → New Terminal**.
8. Type this. Press **Enter**:

```bash
aws --version
```

9. **Pass:** a line that starts with `aws-cli/2.`.
10. Stop. Do not type `aws configure` yet.

---

## Install Terraform

You need Terraform **1.5** or newer.

1. Click **Terminal → New Terminal**.
2. Type this. Press **Enter**:

```bash
terraform version
```

3. If you see version **1.5** or newer, skip to Stage **2**.
4. Type this. Press **Enter**. Wait:

```bash
winget install -e --id HashiCorp.Terraform --accept-package-agreements --accept-source-agreements
```

5. If Windows asks **Do you want to allow this app**, click **Yes**.
6. Kill the terminal. Click **Terminal → New Terminal**.
7. Type this. Press **Enter**:

```bash
terraform version
```

8. **Pass:** `Terraform v1.` and the number is **1.5** or newer.
9. If `winget` failed: browser → https://developer.hashicorp.com/terraform/install → Windows **AMD64** **Download** → extract the zip → copy `terraform.exe` into a folder such as `C:\terraform` → add that folder to your user **Path** → new terminal → `terraform version`.

**Stop here until:** Docker running, `claim-zero:latest` listed, AWS console opens in **`us-east-1`**, `aws --version` is v2, `terraform version` is 1.5 or newer.

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

**Stop here until:** `aws sts get-caller-identity` works, tag **`latest`** is on ECR repo **`claim-zero`**.

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

**Day 2 is done when:** tag **`latest`** is in ECR, ECS **Running tasks = 1**, the landing page loads at **`http://PUBLIC_IP`**.

Do not run `terraform destroy`. Do not go on to GitHub or CodePipeline in this file.
