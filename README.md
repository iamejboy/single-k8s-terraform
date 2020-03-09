**Single Node Kubernetes Cluster - Ubuntu OS, with Terraform option to GCP**
=====================
This is a very simple bash script to bootstrap a single node Kubernetes cluster using Ubuntu OS for testing purpose.\
An option using terraform to GCP google cloud engine is provided that can be easily fire and destroy after use.\
This is intented for learning purpose only of kubernetes and terraform.

Installation
-------------------------------------------
### Inside a provisioned Ubuntu 16.04 LTS/18.04 LTS machine:
- Run below commands.
```sh
$ git clone https://github.com/iamejboy/single-k8s-terraform.git
$ cd single-k8s-terraform
$ ./install.sh
$ kubectl get pods -n kube-system         # Check
```

### Using terraform:
Requirements:
- [Terraform](https://www.terraform.io) installed on your computer.
- [Google Cloud Platform](https://cloud.google.com/) (GCP) account.
- Downloaded your json [GCP credential file](https://cloud.google.com/iam/docs/creating-managing-service-account-keys).

Run below commands:
```sh
$ git clone https://github.com/iamejboy/single-k8s-terraform.git
$ cd single-k8s-terraform/terraform
$ export GOOGLE_CREDENTIALS="/path-to-your-GCP-credential-file-json"
$ export GOOGLE_PROJECT="your-google-project-id"
$ export TF_VAR_gce_username="username"    # desired compute engine ssh user-name
$ export TF_VAR_gce_machine_type="custom-6-20480" # optional, custom-6-20480 is for 6 vCPU and 20GB of RAM. Default is n1-standard-4.
# other optional env variable TF_VAR_(gce_os_image|gcp_region|gcp_zone)
$ ssh-keygen -t rsa -f gcp_compute_k8s -C "$TF_VAR_gce_username"
$ terraform init
$ terraform plan
$ terraform apply
```
Copy `kubectl` commands appeared on standard output, with substituting the `PUBLIC_IP` to access the k8s cluster on your local machine.\
Run `terraform destroy` for cleanup.
