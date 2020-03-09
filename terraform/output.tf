output "PUBLIC_IP" {
 value = google_compute_instance.my-single-k8s.network_interface.0.access_config.0.nat_ip
}
