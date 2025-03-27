Here's the updated `README.md` tailored with an architecture diagram, plus details on how this infrastructure meets **CMMC compliance** at a technical level:

---

### 📄 `README.md`

```markdown
# 🛡️ CMMC-Compliant AWS Infrastructure

This Terraform configuration provisions an AWS environment aligned with **CMMC (Cybersecurity Maturity Model Certification)** requirements using modular Infrastructure-as-Code (IaC).

---

## 📐 Architecture Diagram

```text
                        ┌──────────────────────┐
                        │    Trusted IP Range  │
                        └────────────┬─────────┘
                                     │
                           ┌─────────▼─────────┐
                           │     VPC (10.0.0.0/16)     │
                           └─────────┬─────────┘
                                     │
       ┌─────────────────────────────┴─────────────────────────────┐
       │                        Subnets (A & B)                     │
       │   ┌────────────┐                       ┌──────────────┐    │
       │   │  EC2 w/ IAM│                       │  RDS PostgreSQL │    │
       │   │ (EBS + KMS)│                       │  (KMS-encrypted)│    │
       │   └────┬───────┘                       └──────────────┘    │
       │        │                                                     │
       │   ┌────▼────┐      ┌────────────┐      ┌────────────────┐    │
       │   │  S3 Log │◄─────┤ Flow Logs  ├─────►│ CloudWatch Logs│    │
       │   │  Bucket │      └────────────┘      └────────────────┘    │
       └──────────────────────────────────────────────────────────────┘
                                     │
                            ┌────────▼────────┐
                            │   AWS Config    │
                            │(Recorder + Role)│
                            └─────────────────┘
```

---

## 🔧 Project Structure

```
CMMC/
├── main.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
├── providers.tf
├── modules/
│   ├── compute/       # EC2 with IAM, EBS, userdata
│   ├── config/        # AWS Config Recorder + Role
│   ├── kms/           # KMS key with policy
│   ├── logging/       # VPC Flow Logs + CloudWatch
│   ├── networking/    # VPC, subnets, routing, SGs
│   ├── rds/           # Encrypted PostgreSQL instance
│   └── s3/            # Encrypted S3 buckets for logs and data
```

---

## 🧱 Modules

Each module encapsulates its own:
- `main.tf`: Resource definitions
- `variables.tf`: Input variables
- `outputs.tf`: Output values

This promotes **reusability, clarity, and control**.

---

## ✅ How It Meets CMMC Compliance

| Requirement                     | Terraform Implementation                                                                 |
|--------------------------------|-------------------------------------------------------------------------------------------|
| **Access Control (AC)**         | Security Groups restrict ingress to trusted IPs                                         |
| **Audit & Accountability (AU)**| Flow Logs to CloudWatch, AWS Config for auditing                                         |
| **Configuration Management (CM)** | AWS Config tracks resource drift and changes                                             |
| **Identification & Authentication (IA)** | IAM roles and least-privilege policies for services and EC2                           |
| **Media Protection (MP)**       | All storage (S3, EBS, RDS) encrypted via KMS                                             |
| **System & Communications Protection (SC)** | VPC isolation, subnet design, no public access on sensitive resources                 |
| **System Integrity (SI)**       | EBS volume encryption, secure AMIs, and userdata scripts enforce updates and controls    |

---

## 🚀 Getting Started

1. **Configure AWS CLI**:
   ```bash
   aws configure
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan Infrastructure**:
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

4. **Apply Infrastructure**:
   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

---

## 🔐 Security Summary

✅ **KMS Encryption**  
✅ **IAM Role Least Privilege**  
✅ **CloudTrail-ready Logging**  
✅ **Audit with AWS Config**  
✅ **No hard-coded secrets**  

---

## 🧹 Clean Up

To destroy all resources created:

```bash
terraform destroy -var-file="terraform.tfvars"
```

---

## 📄 License

MIT © Coldchain Secure
```

---

Let me know if you want:
- Compliance mapping to CMMC Levels 1–3  
- GitHub badge integration  
- A Markdown diagram instead of ASCII  
- Visual infrastructure charts via Mermaid or PlantUML
