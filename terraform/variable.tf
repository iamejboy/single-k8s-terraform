variable "gce_username" {}

variable "gce_machine_type" {
  default = "n1-standard-4"
}

variable "gce_os_image" {
  default = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable "gcp_region" {
  default = "asia-northeast1"
}

variable "gcp_zone" {
  default = "asia-northeast1-a"
}
