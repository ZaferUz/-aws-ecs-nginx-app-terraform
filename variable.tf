variable "domain" {
  type = string
  description = "FQDN"
  default = "drzaferuzunco.uk"
}

variable "geo_loadbalancer" {
  type = string
  description = "The commong name of app loadbalancer"
  default = "nginx-app"
}
