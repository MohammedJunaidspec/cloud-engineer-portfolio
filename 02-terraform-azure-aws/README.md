# Project 02: Infrastructure as Code with Terraform on Azure and AWS

## Goal
Build a small, repeatable Azure network with Terraform instead of clicking in the portal, then destroy it to keep cost near zero.

## What I built
- Resource group: `rg-tf-lab` (UAE North)
- Virtual network `vnet-tf-lab` (10.10.0.0/16)
- Subnet `snet-web` (10.10.1.0/24)
- Network security group `nsg-web` with an SSH rule, attached to the subnet
- Storage account with a random name (LRS)

## Tools
Terraform, Azure CLI, Azure, PowerShell, Git

## How to run it
1. `az login --tenant <your-tenant-id>`
2. Create `terraform.tfvars` with `subscription_id = "<your-id>"`
3. `terraform init`, `terraform validate`, `terraform plan`
4. `terraform apply`
5. `terraform destroy` when finished

## Screenshots
## Part 1: Azure screenshots

![budget](images/01-budget.png)

Terraform plan (7 resources to add):

![plan](images/02-azure-plan.png)

Terraform apply complete:

![apply](images/03-azure-apply.png)

Resource group in the Azure portal:

![resource group](images/04-azure-rg.png)

Subnet attached to the NSG:

![subnet](images/05-azure-vnet.png)

NSG rule:

![nsg](images/06-azure-nsg.png)

Destroy complete:

![destroy](images/07-azure-destroy.png)

Resource groups after destroy (only my other lab remains):

![after destroy](images/08-azure-rg-after-destroy.png)

## Problems I hit and how I fixed them
- `az login` failed because my tenant needed multi-factor authentication. Fixed with `az login --tenant <tenant-id>`.
- `terraform plan` said "No configuration files" because my `main.tf` was not saved in the folder. I recreated the files and re-ran `init`.

## Security note
The SSH rule allows port 22 from any source. This is fine for a short lab, but in real use the source should be limited to a trusted IP range.

## Cost control
I set a budget alert, kept to free or very cheap resources, and ran `terraform destroy` after taking screenshots.

## What I learned
- How Terraform plans, applies and destroys infrastructure
- How state tracks what exists in Azure
- How to keep secrets (`*.tfvars`, state files) out of Git

## Next
Add the same network on AWS using Terraform.


Ctrl+End
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/c13316d3-de21-4dd7-b078-cfc0bcfafd9e" />
## Part 2: The same network on AWS

I built the same idea on AWS in the Sydney region (ap-southeast-2). My free-plan account is fixed to that region, so I used it.

| Piece | Azure | AWS |
|---|---|---|
| Network | Virtual network (10.10.0.0/16) | VPC (10.20.0.0/16) |
| Subnet | Subnet (10.10.1.0/24) | Public subnet (10.20.1.0/24) |
| Firewall | Network security group, SSH rule | Security group, SSH only from my IP (/32) |
| Internet path | Built in | Internet gateway + route table + association |
| Storage | Storage account (LRS) | S3 bucket, public access blocked, encrypted |

### AWS result
- `terraform plan` showed 10 resources to add.
- `terraform apply` created all 10.
- I checked the VPC, the security group rule and the private S3 bucket in the console.
- `terraform destroy` removed all 10, so nothing is left running.

### AWS screenshots
Terraform plan:

![aws plan](images/09-aws-terraform-plan.png)

Terraform apply:

![aws apply](images/10-aws-terraform-apply.png)

VPC in the console:

![aws vpc](images/11-aws-vpc-console.png)

Security group, SSH from my IP only:

![aws security group](images/12-aws-security-group-ssh-my-ip.png)

S3 bucket, block all public access on:

![aws s3](images/13-aws-s3-block-public-access.png)

Destroy complete:

![aws destroy](images/14-aws-terraform-destroy-complete.png)

### Problems and fixes
- AWS refused a security group name starting with `sg-`. I renamed it `ssh-from-my-ip`.
- My free-plan account has no region selector, so I used Sydney instead of the UAE.
- I used `aws login` (browser sign-in) instead of long-lived access keys.

### What I learned
- The same design needs different building blocks on each cloud.
- SSH from one IP only (/32) is a simple, strong default.
- Block public access on S3 from day one.
