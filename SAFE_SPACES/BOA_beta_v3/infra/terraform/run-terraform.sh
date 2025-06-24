#!/bin/bash

# Terraform Build Runner Script
# Usage: ./run-terraform.sh [plan|apply|destroy|validate|fmt]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists and load it
if [ -f ".env" ]; then
    print_status "Loading environment variables from .env file"
    export $(cat .env | grep -v '^#' | xargs)
fi

# Default action
ACTION=${1:-plan}

# Validate action
case $ACTION in
    plan|apply|destroy|validate|fmt)
        print_status "Action: $ACTION"
        ;;
    *)
        print_error "Invalid action: $ACTION"
        echo "Usage: $0 [plan|apply|destroy|validate|fmt]"
        exit 1
        ;;
esac

# Check for required AWS credentials
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    print_warning "AWS credentials not found in environment variables"
    print_status "Checking for AWS credentials file..."
    
    if [ ! -f "$HOME/.aws/credentials" ]; then
        print_error "AWS credentials not found. Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables or configure AWS CLI."
        exit 1
    else
        print_success "AWS credentials file found"
    fi
fi

# Set environment variables based on action
case $ACTION in
    apply)
        export APPLY=true
        print_warning "Setting APPLY=true - Terraform will apply changes!"
        ;;
    destroy)
        export APPLY=true
        export DESTROY=true
        print_warning "Setting DESTROY=true - Terraform will destroy infrastructure!"
        ;;
    *)
        export APPLY=false
        ;;
esac

# Create output directory if it doesn't exist
mkdir -p output

print_status "Starting Terraform build container..."

# Run the container
docker-compose run --rm terraform-build

print_success "Terraform build completed!" 