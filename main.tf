terraform {
  backend "s3" {
    bucket = "ercan-tf-state"
    key    = "nginx-app/route53.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "ecs_alb_virginia" {
source = "../modules/find-alb/"
aws_region = "us-east-1"
}

module "ecs_alb_ireland" {
source = "../modules/find-alb/"
aws_region = "eu-west-1"
}

resource "aws_route53_zone" "public" {
  name = var.domain
}

resource "aws_route53_health_check" "virginia" {
  fqdn              = module.ecs_alb_virginia.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "virginia-alb-health-check"
  }
}

resource "aws_route53_health_check" "ireland" {
  fqdn              = module.ecs_alb_ireland.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "ireland-alb-health-check"
  }
}

resource "aws_route53_record" "default" {
  zone_id = aws_route53_zone.public.zone_id
  name    = var.geo_loadbalancer
  type    = "A"
  set_identifier = "Default Traffic to EU"
  health_check_id = aws_route53_health_check.ireland.id

  geolocation_routing_policy {
    country  = "*"
  }

  alias {
    name                   = module.ecs_alb_ireland.alb_dns_name
    zone_id                = module.ecs_alb_ireland.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "virginia" {
  zone_id = aws_route53_zone.public.zone_id
  name    = var.geo_loadbalancer
  type    = "A"
  set_identifier = "US Load Balancer"
  health_check_id = aws_route53_health_check.virginia.id

  geolocation_routing_policy {
    continent = "NA"
  }

  alias {
    name                   = module.ecs_alb_virginia.alb_dns_name
    zone_id                = module.ecs_alb_virginia.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ireland" {
  zone_id = aws_route53_zone.public.zone_id
  name    = var.geo_loadbalancer
  type    = "A"
  set_identifier = "EU Load Balancer"
  health_check_id = aws_route53_health_check.ireland.id


  geolocation_routing_policy {
    continent = "EU"
  }

  alias {
    name                   = module.ecs_alb_ireland.alb_dns_name
    zone_id                = module.ecs_alb_ireland.alb_zone_id
    evaluate_target_health = true
  }
}

output "update_ns_records" {
  value = aws_route53_zone.public.name_servers
}
