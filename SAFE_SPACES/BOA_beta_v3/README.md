Here's your enhanced and tailored `README.md` for the **CMMC-Compliant AWS Infrastructure**. It includes diagrams and highlights how the infrastructure aligns with **CMMC** requirements:

---

### 📄 `README.md`

```markdown
# 🛡️ CMMC-Compliant AWS Infrastructure on AWS with Terraform

This project provisions a modular, secure, and compliant cloud environment aligned with **Cybersecurity Maturity Model Certification (CMMC)** standards using Terraform on AWS.

---

## 📦 Project Structure

```
BOA_beta_v3/
├── infra/terraform/           # Terraform infrastructure code
│   ├── Dockerfile            # Terraform build container
│   ├── docker-compose.yml    # Container orchestration
│   ├── run-terraform.sh      # Convenience script
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Variable definitions
│   ├── terraform.tfvars      # Variable values
│   └── modules/              # Terraform modules
├── backend/                   # MCP server and agents
├── frontend/                  # Angular dashboard
├── docker-compose.yml         # Main application orchestration
└── output/                    # Analysis results and reports
```

Each module is responsible for a discrete part of the infrastructure, ensuring security and compliance boundaries.

---

## 🐳 Dockerized Terraform Build

The project includes a containerized Terraform build environment for consistent, isolated infrastructure deployments.

### Quick Start with Terraform Container

1. **Set up environment variables:**
   ```bash
   cd infra/terraform
   cp env.example .env
   # Edit .env with your AWS credentials
   ```

2. **Run Terraform operations:**
   ```bash
   # Create a plan (default)
   ./run-terraform.sh

   # Apply changes
   ./run-terraform.sh apply

   # Validate configuration
   ./run-terraform.sh validate
   ```

3. **Using Docker Compose:**
   ```bash
   # From project root
   docker-compose run --rm terraform-build

   # Apply changes
   APPLY=true docker-compose run --rm terraform-build
   ```

### Terraform Container Features

- **Consistent Environment**: Terraform 1.7.0 with AWS CLI and Python tools
- **Security**: Runs as non-root user with resource limits
- **Automation**: Automatic initialization, validation, and formatting
- **Integration**: Works with the main application stack

For detailed Terraform container documentation, see [infra/terraform/README.md](infra/terraform/README.md).

---

## 🧭 Architecture Diagram

```text
                           +-----------------------------+
                           |     AWS Config + CloudTrail |
                           |      (Monitoring & Audit)   |
                           +--------------+--------------+
                                          |
                                  +-------+-------+
                                  |               |
                           +------+------++-------+------+
                           |  S3 Buckets  ||   CloudWatch |
                           | (Data & Logs)||   Flow Logs |
                           +------+------++-------+------+
                                  |               |
                                  |               |
                          +-------+---------------+--------+
                          |   VPC (Private & Public Subnets) |
                          +----------------+----------------+
                                           |
                   +-----------------------+-----------------------+
                   |                                               |
        +----------+----------+                       +------------+------------+
        |    EC2 Compute       |                       |         RDS PostgreSQL  |
        |   + KMS + IAM + SSM  |                       |   + Subnet Group + KMS  |
        +----------------------+                       +-------------------------+
```

---

## ✅ Compliance-Driven Features

| Component      | CMMC Capability                        | Implementation                            |
|----------------|----------------------------------------|--------------------------------------------|
| **Encryption** | SC.L2-3.13.11, SC.L2-3.13.16           | KMS for S3, RDS, EBS                        |
| **Audit Logs** | AU.L2-3.3.1, AU.L2-3.3.2               | CloudWatch Logs, AWS Config, VPC Flow Logs |
| **Access Ctrl**| AC.L2-3.1.1, AC.L2-3.1.2               | IAM Roles w/ Least Privilege               |
| **Patch Mgmt** | SI.L2-3.14.1                           | (Option to use SSM Patch Compliance)       |
| **Boundary Prot** | SC.L2-3.13.1, SC.L2-3.13.5         | Security Groups, VPC, Subnet Isolation     |
| **Backup**     | CP.L2-3.8.1, CP.L2-3.8.3               | Encrypted S3 Log Storage                   |

---

## 🚀 Getting Started

### Option 1: Using Docker (Recommended)

1. **Start the full application stack:**
   ```bash
   docker-compose up -d
   ```

2. **Run Terraform build:**
   ```bash
   # Create infrastructure plan
   docker-compose run --rm terraform-build

   # Apply infrastructure changes
   APPLY=true docker-compose run --rm terraform-build
   ```

### Option 2: Local Development

1. **Install Terraform**
   ```bash
   brew install terraform     # Mac
   sudo apt install terraform # Debian/Ubuntu
   ```

2. **AWS CLI Setup**
   ```bash
   aws configure
   ```

3. **Clone and Initialize**
   ```bash
   git clone https://github.com/YOUR_ORG/BOA_beta_v3.git
   cd BOA_beta_v3/infra/terraform
   terraform init
   ```

4. **Customize Variables**
   Edit `terraform.tfvars` with your deployment-specific settings.

5. **Deploy Infrastructure**
   ```bash
   terraform plan -var-file="terraform.tfvars"
   terraform apply -var-file="terraform.tfvars"
   ```

---

## 🔐 Security Features

- **Data Encryption**: All storage (EBS, RDS, S3) uses **customer-managed KMS keys**
- **Auditing & Logging**: AWS Config + VPC Flow Logs + IAM Role tracking
- **Principle of Least Privilege**: IAM roles scoped per service/module
- **Secure Networking**: Subnet isolation, no public RDS, ingress limited to `trusted_ip_range`

---

## 🧹 Tear Down

### Using Docker:
```bash
# Destroy infrastructure
docker-compose run --rm terraform-build destroy
```

### Using Local Terraform:
```bash
terraform destroy -var-file="terraform.tfvars"
```

---

## 🧪 Testing & Hardening Suggestions

- Enable **GuardDuty**, **Security Hub**, or **Macie**
- Integrate with **AWS SSM Patch Compliance**
- Add CI/CD validation (e.g., GitHub Actions, OPA/Conftest checks)
- Extend IAM Roles with session control & MFA

---

## 📄 License

MIT © [Coldchain Secure](https://coldchainsecure.com)

```

---

Would you like a `README.architecture.png` diagram version generated as well, or should we proceed to audit the modules for any edge cases or security oversights?