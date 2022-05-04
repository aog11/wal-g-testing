output "pgsql-vm1_name" {
    value = google_compute_instance.pgsql-vm[0].name
}

output "pgsql-vm1_ip_info" {
  value = "private: ${google_compute_instance.pgsql-vm[0].network_interface.0.network_ip}, public: ${google_compute_instance.pgsql-vm[0].network_interface.0.access_config.0.nat_ip}"
}

output "pgsql-vm2_name" {
    value = google_compute_instance.pgsql-vm[1].name
}

output "pgsql-vm2_ip_info" {
  value = "private: ${google_compute_instance.pgsql-vm[1].network_interface.0.network_ip}, public: ${google_compute_instance.pgsql-vm[1].network_interface.0.access_config.0.nat_ip}"
}

output "add_ssh_keys" {
  value = "ssh_new_conn ${google_compute_instance.pgsql-vm[0].network_interface.0.access_config.0.nat_ip} ${google_compute_instance.pgsql-vm[1].network_interface.0.access_config.0.nat_ip}"
}

output "wal_g_bucket_info" {
  value = google_storage_bucket.wal_g_bucket.url
}