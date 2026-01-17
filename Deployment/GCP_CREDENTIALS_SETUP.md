# GCP Credentials Setup Guide

## Overview
The deployment requires Google Cloud Platform credentials to authenticate and provision resources.

## Step 1: Create a GCP Service Account

1. Go to Google Cloud Console: https://console.cloud.google.com
2. Select your project (or create a new one)
3. Navigate to: **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
5. Fill in:
   - **Service Account Name**: `team12-deployment`
   - **Service Account ID**: `team12-deployment` (auto-filled)
   - **Description**: `Service account for Team12 Infrastructure Deployment`
6. Click **Create and Continue**

## Step 2: Grant Required Permissions

Add these roles to the service account:
- `Kubernetes Engine Admin` - For GKE cluster management
- `Cloud SQL Admin` - For database provisioning
- `Compute Admin` - For VPC and networking
- `Service Account User` - For service account usage
- `Service Networking Admin` - For private IP setup
- `Compute Network Admin` - For network management

### How to assign roles:
1. In the Service Account details page, click **Grant Access**
2. Add each role one by one
3. Click **Save**

## Step 3: Create and Download JSON Key

1. Go to the Service Account page
2. Click on the service account you created
3. Go to **Keys** tab
4. Click **Add Key** → **Create new key**
5. Select **JSON** format
6. Click **Create**
7. The JSON file will download automatically

## Step 4: Place the Key File

1. Copy the downloaded JSON file
2. Rename it to `credentials.json`
3. Place it in the **repository root** (same folder as `Scripts/` and `Team12/`)

```bash
cp ~/Downloads/[downloaded-key].json ./credentials.json
```

## Step 5: Secure the Credentials File

⚠️ **IMPORTANT**: The `credentials.json` file is already in `.gitignore` and should NEVER be committed to git.

Verify:
```bash
# Check if file is ignored
git check-ignore credentials.json
# Should output: credentials.json
```

## File Structure

Your project should now have:
```
.
├── credentials.json          ← Your actual GCP credentials (NOT in git)
├── Scripts/
├── Team12/
└── Terraform/
```

## Verify Setup

Test the credentials before deployment (from the repo root):

```bash
gcloud auth activate-service-account --key-file=credentials.json
gcloud config set project [YOUR_PROJECT_ID]
gcloud compute projects describe [YOUR_PROJECT_ID]
```

If the last command shows project details, your credentials are valid!

## Troubleshooting

### "Invalid credentials" Error
- Verify the JSON file is valid (not corrupted)
- Check that the service account has the required roles
- Ensure the project ID in credentials matches your project

### "Permission denied" Error
- The service account is missing required roles
- Add the roles listed in Step 2
- Wait a few minutes for permissions to propagate

### "credentials.json not found"
- Verify the file is in the **repository root**
- Check the filename is exactly `credentials.json`
- Make sure it's not named `credentials.json.example`

## Security Best Practices

1. ✅ Use service accounts for IaC (never use personal accounts)
2. ✅ Use separate service accounts for different environments
3. ✅ Regularly rotate service account keys
4. ✅ Keep credentials.json in .gitignore
5. ✅ Use minimal required permissions (principle of least privilege)
6. ✅ Monitor service account usage in GCP audit logs
7. ✅ Delete old/unused service accounts

## Rotation Instructions

To rotate credentials:

1. Create a new JSON key in GCP
2. Replace `credentials.json` locally
3. Run `gcloud auth activate-service-account --key-file=credentials.json`
4. Delete the old key in GCP Console
5. Commit the changes (only if using CI/CD secrets management)

## Resources

- [GCP Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Creating and managing service accounts](https://cloud.google.com/iam/docs/creating-managing-service-accounts)
- [Service Account Keys](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)
