# GitLab Registry Access Setup

## Overview
The Kubernetes manifests use `imagePullSecrets` to access private images from GitLab Container Registry. This guide explains how to set up these credentials.

## Prerequisites
- GitLab account with access to the project
- kubectl access to your Kubernetes cluster
- GitLab Personal Access Token or Deploy Token

## Step 1: Create GitLab Credentials

### Option A: Using Personal Access Token
1. Go to GitLab: `https://gitlab.com/-/user_settings/personal_access_tokens`
2. Create a new token with `read_registry` scope
3. Copy the token

### Option B: Using Deploy Token
1. Go to your project: `https://gitlab.com/kdg-ti/integratieproject-j3/teams-25-26/team12`
2. Settings → CI/CD → Deploy Tokens
3. Create a new token with `read_registry` scope
4. Copy the username and token

## Step 2: Create Kubernetes Secret

### Recommended: Use the helper script
```bash
cd Team12/Scripts
./setup-gitlab-registry.sh
```
The script prompts for your token and creates `gitlab-registry` in the `bordspelplatform-12` namespace.

### Manual fallback
```bash
kubectl create namespace bordspelplatform-12 --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry gitlab-registry \
  --docker-server=registry.gitlab.com \
  --docker-username=oauth2 \
  --docker-password=<YOUR_TOKEN> \
  --docker-email=<YOUR_EMAIL> \
  -n bordspelplatform-12
```

**Replace:**
- `<YOUR_TOKEN>` - Your personal access token or deploy token
- `<YOUR_EMAIL>` - Your GitLab email

## Step 3: Verify the Secret

```bash
kubectl get secrets gitlab-registry -n bordspelplatform-12
kubectl describe secret gitlab-registry -n bordspelplatform-12
```

## Step 4: Deploy the Pods

Once the secret is created, deploy your pods:

```bash
kubectl get pods -n bordspelplatform-12 -w
```

## Troubleshooting

### ImagePullBackOff Error
If you see `ImagePullBackOff` errors, the secret might not be configured correctly:

```bash
# Check pod events
kubectl describe pod <pod-name> -n bordspelplatform-12

# Check secret exists
kubectl get secrets -n default | grep gitlab-registry
```

### Invalid Credentials
- Verify the token has `read_registry` scope
- Ensure the registry URL is `registry.gitlab.com`
- If using a PAT, set `--docker-username=oauth2` (GitLab PAT username)

### Registry Access Denied
- Ensure your token hasn't expired
- Verify project visibility and your access permissions
- Check if the token is active in GitLab settings

## Security Notes

⚠️ **Important:**
- Never commit credentials or tokens to git
- Use deploy tokens for CI/CD pipelines (more secure)
- Rotate tokens regularly
- The `gitlab-registry` secret is created at cluster setup time, not in version control

## Additional Resources

- [GitLab Container Registry Documentation](https://docs.gitlab.com/ee/user/packages/container_registry/)
- [Kubernetes Image Pull Secrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
- [GitLab Deploy Tokens](https://docs.gitlab.com/ee/user/project/deploy_tokens/)
