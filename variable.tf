variable "domain" {
  type = string
  description = "FQDN"
  default = "my-test-domain.com"
}

variable "geo_loadbalancer" {
  type = string
  description = "The commong name of app loadbalancer"
  default = "nginx-app"
}
