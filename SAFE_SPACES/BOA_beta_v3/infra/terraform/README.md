# Terraform Build Container

This directory contains a Dockerized Terraform build environment for the BOA Beta v3 infrastructure.

## Overview

The Terraform build container provides a consistent, isolated environment for running Terraform operations. It includes:

- Terraform 1.7.0
- AWS CLI
- Python 3 with boto3 for cost analysis
- Additional tools: jq, curl, git, bash

## Quick Start

### 1. Set up Environment Variables

Copy the example environment file and configure it:

```bash
cp env.example .env
# Edit .env with your AWS credentials and configuration
```

### 2. Run Terraform Operations

#### Using the convenience script:

```bash
# Create a plan (default)
./run-terraform.sh

# Apply changes
./run-terraform.sh apply

# Validate configuration
./run-terraform.sh validate

# Format Terraform files
./run-terraform.sh fmt

# Destroy infrastructure (use with caution!)
./run-terraform.sh destroy
```

#### Using Docker Compose directly:

```bash
# Create a plan
docker-compose run --rm terraform-build

# Apply changes
APPLY=true docker-compose run --rm terraform-build
```

## Configuration

### Environment Variables

The following environment variables can be set in your `.env` file:

#### AWS Configuration
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_DEFAULT_REGION`: AWS region (default: us-west-1)
- `AWS_SESSION_TOKEN`: Session token for temporary credentials

#### Terraform Variables
- `TF_VAR_environment`: Environment name (default: production)
- `TF_VAR_project`: Project name (default: BOA_Beta_v3)
- `TF_VAR_owner`: Owner tag (default: coldchainsecure)
- `TF_VAR_cost_center`: Cost center tag (default: IT)

#### Build Configuration
- `APPLY`: Set to `true` to apply changes, `false` to only create plan

### AWS Credentials

You can provide AWS credentials in two ways:

1. **Environment Variables**: Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your `.env` file
2. **AWS Credentials File**: Mount your `~/.aws/credentials` file (automatically done by the container)

## Container Features

### Security
- Runs as non-root user (UID 1000)
- Resource limits to prevent resource exhaustion
- Health checks to ensure container is working properly

### Persistence
- Output directory mounted to `./output` for plan files and logs
- State directory mounted to `./state` (optional)
- AWS credentials mounted from host

### Automation
- Automatic Terraform initialization
- Validation and formatting
- Plan creation with optional apply
- Colored output for better readability

## Directory Structure

```
infra/terraform/
├── Dockerfile              # Container definition
├── docker-compose.yml      # Container orchestration
├── .dockerignore          # Files to exclude from build
├── run-terraform.sh       # Convenience script
├── env.example            # Environment variables template
├── README.md              # This file
├── main.tf                # Main Terraform configuration
├── variables.tf           # Variable definitions
├── outputs.tf             # Output definitions
├── backend.tf             # Backend configuration
├── providers.tf           # Provider configuration
├── terraform.tfvars       # Variable values
└── modules/               # Terraform modules
```

## Integration with Main Application

The Terraform build container is integrated into the main `docker-compose.yml` file and can be used alongside other services:

```bash
# Start all services including Terraform build
docker-compose up -d

# Run Terraform build specifically
docker-compose run --rm terraform-build
```

## Troubleshooting

### Common Issues

1. **AWS Credentials Not Found**
   - Ensure your `.env` file has the correct AWS credentials
   - Or configure AWS CLI on your host machine

2. **Permission Denied**
   - The container runs as UID 1000, ensure your user has appropriate permissions
   - Check that output directories are writable

3. **Terraform State Issues**
   - Ensure the S3 backend is properly configured in `backend.tf`
   - Check that the S3 bucket exists and is accessible

### Logs

Container logs are available through Docker:

```bash
# View logs
docker-compose logs terraform-build

# Follow logs in real-time
docker-compose logs -f terraform-build
```

## Best Practices

1. **Always review plans before applying**
   - Use `./run-terraform.sh` to create a plan first
   - Review the plan output carefully
   - Only apply when you're confident about the changes

2. **Use environment-specific configurations**
   - Create different `.env` files for different environments
   - Use different Terraform workspaces or state files

3. **Backup your state**
   - The state is stored in S3, but consider additional backups
   - Use Terraform state locking to prevent concurrent modifications

4. **Monitor costs**
   - Use the cost estimation features
   - Set up AWS billing alerts
   - Review infrastructure regularly

## Contributing

When making changes to the Terraform configuration:

1. Test changes in a development environment first
2. Update the documentation
3. Ensure all variables are properly documented
4. Test the container build process 