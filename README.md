# Deploy to EKS Composite Action

This composite action provides a standardized workflow for deploying services to an Amazon EKS cluster using Helm. It integrates with a centralized Helm values repository to manage environment-specific configurations.

## Features

- **Standardized Deployments:** Enforces a consistent deployment process across all services.
- **Centralized Configuration:** Uses a separate repository for Helm values, promoting consistency and easier management.
- **AWS Integration:** Assumes an IAM role and logs into ECR automatically.
- **Optional API Docs Update:** Can trigger a workflow to update API documentation after a successful deployment.

## Usage

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write # Required for AWS OIDC
    steps:
      - name: Deploy to Staging
        uses: zimran/zimran-actions@v1
        with:
          service_name: 'my-service'
          environment: 'staging'
          helm_version: '1.2.3'
          k8s_namespace: 'my-namespace'
          image_name: ${{ steps.docker-build.outputs.image-name }}
          product_name: 'my-product'
          values_repository: 'my-org/my-helm-values'
          aws_role: 'arn:aws:iam::123456789012:role/my-deploy-role'
          aws_region: 'us-east-1'
          cluster_name: 'my-eks-cluster'
          github_pat: ${{ secrets.MY_PAT }} # If values repo is private
```

## Inputs

| Input               | Description                                                                                                   | Required | Default                             |
|---------------------|---------------------------------------------------------------------------------------------------------------|----------|-------------------------------------|
| `service_name`      | The name of the service to deploy. Must match the service name in the values repository.                      | `true`   | `N/A`                               |
| `environment`       | The deployment environment (e.g., 'staging', 'production').                                                   | `true`   | `N/A`                               |
| `helm_version`      | The version of the Helm chart to deploy.                                                                      | `true`   | `N/A`                               |
| `k8s_namespace`     | The Kubernetes namespace to deploy into.                                                                      | `true`   | `N/A`                               |
| `image_name`        | The name of the Docker image to deploy.                                                                       | `true`   | `N/A`                               |
| `product_name`      | The name of the product for documentation purposes.                                                           | `true`   | `N/A`                               |
| `values_repository` | The centralized repository for Helm values (e.g., 'your-org/product-helm-values').                            | `false`  | `'your-org/product-helm-values'`    |
| `aws_role`          | The AWS IAM role to assume for deployment.                                                                    | `true`   | `N/A`                               |
| `aws_region`        | The AWS region of the EKS cluster.                                                                            | `true`   | `N/A`                               |
| `cluster_name`      | The name of the EKS cluster.                                                                                  | `true`   | `N/A`                               |
| `debug_enabled`     | Enable debug output for Helm.                                                                                 | `false`  | `'false'`                           |
| `update_api_docs`   | Set to 'true' to trigger the API documentation update workflow.                                               | `false`  | `'false'`                           |
| `github_pat`        | GitHub Personal Access Token for checking out the values repository. Using `GITHUB_TOKEN` is recommended.     | `false`  | `${{ github.token }}`               |

## Contributing

Contributions are welcome! Please open an issue or submit a pull request. 