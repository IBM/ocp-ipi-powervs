# ocp-ipi-powervs

Terraform automation to kick off an installer-provisioned-infrastructure (IPI) deploy of OpenShift Container Platform on IBM Power Virtual Server (PowerVS).

## Overview

This Terraform project simplifies the deployment of OpenShift Container Platform on IBM PowerVS using the IPI (Installer Provisioned Infrastructure) method. The automation handles:

- DNS zone creation in IBM Cloud DNS Services
- OpenShift installer and CLI tools installation
- Install configuration generation
- Service account and credential management
- Cluster deployment and destruction

## Architecture

The project is organized into the following modules:

- **dns**: Creates IBM Cloud DNS Services instance and zone
- **openshift-tools**: Downloads and installs OpenShift CLI tools (oc, openshift-install, ccoctl)
- **install-config**: Generates the OpenShift install-config.yaml
- **manifests**: Extracts credential requests and creates IBM Cloud service accounts
- **cluster**: Executes the OpenShift installer to create/destroy the cluster

## Prerequisites

- IBM Cloud account with appropriate permissions
- IBM Cloud API key
- SSH key pair for cluster access
- OpenShift pull secret from [Red Hat Console](https://console.redhat.com/openshift/install/pull-secret)
- Existing VPC in IBM Cloud
- SSH access to a bastion/deployment host (can be localhost)
- Terraform >= 1.8.0

## Required IBM Cloud Resources

Before running this automation, ensure you have:

1. **VPC**: An existing VPC in your target region
2. **Resource Group**: An IBM Cloud resource group (default: "Default")
3. **PowerVS Workspace** (optional): Can be created by the installer or use an existing one
4. **Transit Gateway** (optional): Can be created by the installer or use an existing one

## Usage

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ocp-ipi-powervs
```

### 2. Prepare Your Pull Secret

Save your OpenShift pull secret to a file:

```bash
mkdir -p data
# Copy your pull secret content to data/pullSecret
```

### 3. Create a Variables File

Create a `terraform.tfvars` file with your configuration:

```hcl
# IBM Cloud Configuration
api_key        = "your-ibm-cloud-api-key"
ibm_id         = "your-email@example.com"
resource_group = "Default"

# VPC Configuration
vpc_name   = "your-vpc-name"
vpc_region = "us-south"
vpc_zone   = "us-south-1"

# PowerVS Configuration
powervs_region = "dal"
powervs_zone   = "dal10"
# Optional: Use existing PowerVS workspace
# powervs_workspace_guid = "your-workspace-guid"

# Optional: Use existing Transit Gateway
# tg_name = "your-transit-gateway-name"

# Cluster Configuration
cluster_name      = "ocp-powervs"
basedomain        = "example.com"
openshift_release = "4.18.5"
cluster_dir       = "~/ocp-powervs-deploy"

# SSH Configuration
ssh_key      = "ssh-rsa AAAAB3NzaC1yc2E... your-public-key"
ssh_host     = "localhost"
ssh_user     = "root"
ssh_identity = ""  # Optional: SSH agent identity

# Pull Secret
pull_secret_file = "./data/pullSecret"
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review the Plan

```bash
terraform plan
```

### 6. Deploy the Cluster

```bash
terraform apply
```

The deployment process will:
1. Create DNS zone in IBM Cloud DNS Services
2. Download and install OpenShift tools
3. Generate install-config.yaml
4. Create service accounts and credentials
5. Launch the OpenShift installer

**Note**: The cluster deployment can take 45-60 minutes to complete.

### 7. Access Your Cluster

After successful deployment, access information will be available in:

```bash
cat ~/ocp-powervs-deploy/auth/kubeconfig
cat ~/ocp-powervs-deploy/auth/kubeadmin-password
```

Set your KUBECONFIG:

```bash
export KUBECONFIG=~/ocp-powervs-deploy/auth/kubeconfig
oc get nodes
```

### 8. Destroy the Cluster

When you're done, destroy the cluster and associated resources:

```bash
terraform destroy
```

## Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `api_key` | IBM Cloud API key | string | - | yes |
| `basedomain` | Base domain name for the cluster (e.g., example.com) | string | - | yes |
| `cluster_dir` | Directory for cluster configuration and state | string | `"ocp-powervs-deploy"` | no |
| `cluster_name` | Name of the OpenShift cluster | string | - | yes |
| `ibm_id` | Email of the IBM Cloud user deploying the cluster | string | - | yes |
| `openshift_release` | OpenShift release version (e.g., 4.18.5) | string | - | yes |
| `powervs_region` | PowerVS region | string | `"dal"` | no |
| `powervs_zone` | PowerVS zone | string | `"dal10"` | no |
| `powervs_workspace_guid` | Existing PowerVS workspace GUID (optional) | string | `""` | no |
| `pull_secret_file` | Path to OpenShift pull secret file | string | `"./data/pullSecret"` | no |
| `resource_group` | IBM Cloud resource group name | string | `"Default"` | no |
| `ssh_key` | Public SSH key for cluster access | string | - | yes |
| `ssh_host` | SSH host for running commands | string | `"localhost"` | no |
| `ssh_user` | SSH user for running commands | string | `"root"` | no |
| `ssh_identity` | SSH agent identity comment | string | `""` | no |
| `tg_name` | Existing Transit Gateway name (optional) | string | `""` | no |
| `vpc_name` | Name of the VPC to use | string | - | yes |
| `vpc_region` | VPC region | string | `"us-south"` | no |
| `vpc_zone` | VPC zone | string | `"us-south-1"` | no |

## Cluster Configuration

The default cluster configuration includes:

- **Architecture**: ppc64le (Power)
- **Control Plane**: 3 nodes with 0.5 processors each
- **Worker Nodes**: 3 nodes
- **Network Type**: OVNKubernetes
- **Cluster Network**: 10.128.0.0/14
- **Service Network**: 172.30.0.0/16

To customize the cluster configuration, modify the template file:
`modules/install-config/templates/install-config.yaml.tpl`

## SSH Configuration

The automation uses SSH to execute commands on a deployment host. You can:

- **Use localhost**: Run Terraform on the same machine where OpenShift tools will be installed
- **Use a bastion host**: Run Terraform locally but execute commands on a remote bastion host

Ensure SSH agent forwarding is configured if using a remote host:

```bash
ssh-add ~/.ssh/your-key
ssh -A user@bastion-host
```

## Troubleshooting

### Installation Logs

Check the OpenShift installer logs:

```bash
tail -f ~/ocp-powervs-deploy/.openshift_install.log
```

### DNS Issues

Verify DNS zone creation:

```bash
ibmcloud dns zones --instance <dns-instance-name>
```

### Service Account Issues

Check service account creation:

```bash
ibmcloud iam service-ids
```

### Cleanup Failed Deployments

If a deployment fails, you may need to manually clean up resources:

```bash
# Destroy with Terraform
terraform destroy

# Or manually destroy the cluster
cd ~/ocp-powervs-deploy
openshift-install destroy cluster --dir=. --log-level=debug
```

## License

See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Support

For issues and questions:
- Open an issue in this repository
- Consult [OpenShift on PowerVS documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/installing_on_ibm_power_virtual_server/preparing-to-install-on-ibm-power-vs#preparing-to-install-on-ibm-power-vs)
