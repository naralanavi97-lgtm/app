output "vm_external_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

output "cloudsql_private_ip" {
  value = google_sql_database_instance.mysql_instance.private_ip_address
}