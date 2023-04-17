output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}
output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}

output "db_internal_ip" {
  value = module.db.db_internal_ip
}
