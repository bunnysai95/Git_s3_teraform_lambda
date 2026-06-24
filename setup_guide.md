# Lambda Auto-Deploy Setup Guide

**Flow:** `git push` → GitHub Actions → build zip → upload to S3 → `terraform apply` → Lambda updated.

This is your end-to-end reference. Follow it once. After that, every `git push` to `master` auto-deploys.

---

## 0. Pick names first (write them down)

You need a few **globally unique** names. S3 bucket names must be unique across ALL of AWS, so add something random.

| Thing | Example value | Your value |
|-------|---------------|------------|
| AWS region | `us-east-1` | __________ |
| Artifact bucket (holds the zip) | `bunnysai95-lambda-artifacts-8821` | __________ |
| Terraform state bucket | `bunnysai95-tfstate-8821` | __________ |
| Lambda function name | `git-s3-terraform-lambda` | __________ |

> Tip: reuse the same random suffix for both buckets so they're easy to remember.

---

## 1. Project files (already created for you)

```
Git_s3_teraform_lambda/
├── scr/
│   └── lambda_function.py        # your Lambda code
├── terraform/
│   ├── main.tf                   # Lambda + S3 + IAM
│   ├── variables.tf
│   └── outputs.tf
├── .github/
│   └── workflows/
│       └── deploy.yml            # the auto-trigger pipeline
├── requirements.txt              # Python deps (empty for now)
├── .gitignore
├── info.txt
└── SETUP_GUIDE.md                # this file
```

---

## 2. AWS — one-time setup (do this in your browser + local terminal)

### 2a. Install tools on your machine
- **AWS CLI**: https://aws.amazon.com/cli/
- **Terraform**: https://developer.hashicorp.com/terraform/install

Check they work (run in PowerShell):
```powershell
aws --version
terraform version
```

### 2b. Create an IAM user for deployments (AWS Console)
1. Go to **IAM → Users → Create user**. Name it `github-deployer`.
2. **Do NOT** enable console access (this is a machine user).
3. Attach permissions. For simplicity while learning, attach these AWS-managed policies:
   - `AWSLambda_FullAccess`
   - `AmazonS3FullAccess`
   - `IAMFullAccess`
   - `CloudWatchLogsFullAccess`
   > (Later you can tighten these. Full access is fine to get started.)
4. Create the user, then open it → **Security credentials → Create access key**.
5. Choose **Application running outside AWS**. Copy the **Access key ID** and **Secret access key**.
   **You only see the secret once — save it now.**

### 2c. Configure AWS CLI locally with that key
```powershell
aws configure
```
Enter when prompted:
- AWS Access Key ID → (paste)
- AWS Secret Access Key → (paste)
- Default region → `us-east-1`
- Default output → `json`

### 2d. Create the Terraform state bucket (one command)
Terraform stores its "memory" (state) in S3 so GitHub and your laptop agree on what exists.
Replace the name with YOUR state bucket name:
```powershell
aws s3 mb s3://bunnysai95-tfstate-8821 --region us-east-1
```

---

## 3. Fill in your names in the code

Open these files and replace the `REPLACE_ME` placeholders:

**`terraform/main.tf`** — in the `backend "s3"` block:
```hcl
backend "s3" {
  bucket = "bunnysai95-tfstate-8821"   # <-- your STATE bucket
  key    = "lambda/terraform.tfstate"
  region = "us-east-1"
}
```

**`.github/workflows/deploy.yml`** — in the `env:` block:
```yaml
ARTIFACT_BUCKET: bunnysai95-lambda-artifacts-8821   # <-- your ARTIFACT bucket
```

> Note: you do NOT pre-create the artifact bucket. Terraform creates it for you.
> The state bucket IS created manually (step 2d) because Terraform needs it before it can run.

---

## 4. First deploy — run it locally ONCE to confirm it works

Before relying on GitHub, prove the Terraform works from your machine.

```powershell
# from the project root
cd terraform

# build a quick zip manually for the first run
mkdir build
copy ..\scr\lambda_function.py build\
cd build
Compress-Archive -Path * -DestinationPath ..\lambda.zip -Force
cd ..

# upload it to the artifact bucket name you chose
# (the bucket doesn't exist yet, so do init+apply first WITHOUT the backend)
```

**Simplest path:** comment out the `backend "s3"` block in `main.tf` for the very first run, then:
```powershell
terraform init
terraform apply `
  -var="artifact_bucket_name=bunnysai95-lambda-artifacts-8821" `
  -var="artifact_s3_key=lambda/lambda.zip"
```
or this command 
terraform apply -var="artifact_bucket_name=bunnysai95-lambda-artifacts-8821" -var="artifact_s3_key=lambda/lambda.zip"
Type `yes` when prompted.

This creates the S3 bucket, IAM role, and Lambda. Once it succeeds:
1. Uncomment the `backend "s3"` block.
2. Run `terraform init` again and type `yes` to migrate state to S3.

> If you'd rather skip the local run entirely, you can let GitHub Actions do the first
> deploy too — just make sure the state bucket exists (step 2d) and the backend block is filled in.

---

## 5. Connect GitHub & add secrets

### 5a. Add your AWS keys as GitHub secrets
In your repo on GitHub: **Settings → Secrets and variables → Actions → New repository secret**

Add two secrets:
| Name | Value |
|------|-------|
| `AWS_ACCESS_KEY_ID` | the access key from step 2b |
| `AWS_SECRET_ACCESS_KEY` | the secret from step 2b |

> Secrets are encrypted. The pipeline reads them via `${{ secrets.NAME }}`. Never commit keys to code.

### 5b. Push your code
```powershell
cd ..              # back to project root
git add .
git commit -m "add lambda + terraform + ci/cd pipeline"
git push origin master
```

---

## 6. The auto-trigger (this is the magic part)

`.github/workflows/deploy.yml` has:
```yaml
on:
  push:
    branches:
      - master
```

That means: **every time you push to `master`, the pipeline runs automatically.** No manual step.

Each run:
1. Checks out your code
2. Builds the Lambda zip (installs `requirements.txt` deps + your `lambda_function.py`)
3. Uploads the zip to S3
4. Computes a hash of the zip (so Terraform knows the code changed)
5. Runs `terraform apply` → updates the Lambda

Watch it run: repo → **Actions** tab → click the latest run.

---

## 7. Your everyday workflow (after setup)

```powershell
# 1. edit scr/lambda_function.py (your real logic)
# 2. add any new pip packages to requirements.txt
# 3. push:
git add .
git commit -m "describe your change"
git push origin master
# 4. go to the Actions tab and watch it deploy. Done.
```

That's it. You never touch the AWS console for normal updates.

---

## 8. Testing your Lambda

In AWS Console → **Lambda → your function → Test tab → create a test event** (use the default `{}`)
→ **Test**. You should see the `200` response and the log line in the output.

---

## 9. Common issues & fixes

| Problem | Cause | Fix |
|---------|-------|-----|
| `BucketAlreadyExists` | Bucket name not unique | Pick a more random name, update both files |
| `AccessDenied` in Actions | IAM user missing permissions | Re-check policies in step 2b |
| Terraform `backend` errors on first run | State bucket doesn't exist | Run step 2d, or comment out backend for first run |
| Pipeline doesn't trigger | Pushed to wrong branch | Make sure you push to `master` (matches `deploy.yml`) |
| Lambda code not updating | Hash unchanged | The pipeline handles this automatically via `source_code_hash` |

---

## 10. Mental model (so you remember WHY)

- **S3 (artifact bucket)** = a shelf where the zipped code sits.
- **S3 (state bucket)** = Terraform's notebook of what it has built.
- **Terraform** = the builder. Reads its notebook, makes AWS match your `.tf` files.
- **IAM role** = the Lambda's ID badge (what it's allowed to do).
- **GitHub Actions** = the robot that runs the whole chain on every push.
- **The hash** = a fingerprint of your code so Terraform knows when to redeploy.

You describe the *desired end state* in code; the robot makes reality match it.
```
