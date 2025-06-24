# Terraform Build Container
FROM hashicorp/terraform:1.11.2

# Install additional tools and Python packages
RUN apk add --no-cache \
    aws-cli \
    jq \
    curl \
    git \
    bash \
    python3 \
    py3-pip \
    py3-boto3 \
    py3-requests \
    py3-jinja2 \
    su-exec

# Set working directory
WORKDIR /terraform

# Copy Terraform files
COPY . .

# Ensure all shell scripts are executable
RUN find /terraform -type f -name "*.sh" -exec chmod +x {} \;

# Ensure /terraform is owned by UID 1000 (non-root user)
RUN chown -R 1000:1000 /terraform

# Set environment variables
ENV TF_IN_AUTOMATION=1
ENV TF_INPUT=0

# Set entrypoint
ENTRYPOINT ["/terraform/entrypoint.sh"] 