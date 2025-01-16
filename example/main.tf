module "ha_cluster" {
  source            = "../ha-cluster"
  region            = "us-east-1"
  ami_id            = "ami-0c55b159cbfafe1f0"
  instance_type     = "t2.micro"
  database_name     = "mydb"
  database_username = "admin"
  database_password = "Mtfh7BQDjs"
}

module "route_53_mod" {
  source      = "../route_53_mod"
  domain_name = "example.com"
  db_A_record = module.ha_cluster.db_instance_endpoint_share
  lb_frontend_read = module.ha_cluster.lb_frontend_read
  lb_frontend_zone = module.ha_cluster.lb_frontend_zone
  lb_backend_read = module.ha_cluster.lb_backend_read
  lb_backend_zone = module.ha_cluster.lb_backend_zone

}