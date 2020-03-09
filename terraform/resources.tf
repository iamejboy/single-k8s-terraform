resource "google_compute_firewall" "firewall-allow" {
  name    = "firewall-allow"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22","6443","30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["single-k8s"]
}

resource "google_compute_instance" "my-single-k8s" {
  name         = "single-k8s"
  machine_type = var.gce_machine_type
  zone         = var.gcp_zone

  tags = ["single-k8s"]

  boot_disk {
    initialize_params {
      image = var.gce_os_image
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
      }
    }

  connection {
    type        = "ssh"
    user        = var.gce_username
    timeout     = "500s"
    private_key = file("gcp_compute_k8s")
    host = google_compute_instance.my-single-k8s.network_interface.0.access_config.0.nat_ip
  }

  depends_on = [
    google_compute_firewall.firewall-allow,
  ]

  service_account {
    scopes = ["compute-ro", "storage-ro"]
  }

  metadata = {
    ssh-keys = "${var.gce_username}:${file("gcp_compute_k8s.pub")}"
  }

  provisioner "remote-exec" {
    inline = [ 
      "/usr/bin/cloud-init status --wait"
    ]
  }

  provisioner "file" {
    source = "../install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      " sudo chmod +x /tmp/install.sh",
      "/tmp/install.sh"
    ]
  }
}
