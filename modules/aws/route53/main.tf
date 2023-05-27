resource "aws_route53_record" "this" {
  zone_id = var.host_zone_id
  name    = var.record_name
  type    = var.record_type

  alias {
    name                   = var.elb_alias_name
    zone_id                = var.elb_alias_zone_id
    evaluate_target_health = true
  }
}