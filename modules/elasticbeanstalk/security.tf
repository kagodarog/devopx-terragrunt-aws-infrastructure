resource "aws_security_group" "eb-sg" {
  count  = var.elasticbeanstalk_tier == "Worker" ? 1 : 0
  vpc_id = var.vpc_id
  name   = "${local.tags.env_prefix}-eb-sg-custom"
  tags   = local.tags
}

resource "aws_security_group_rule" "eb-sg-rule" {
  for_each          = var.elasticbeanstalk_tier == "Worker" ? local.ingress_rules : {}
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  security_group_id = join("", aws_security_group.eb-sg[*].id)
  cidr_blocks       = each.value.cidr_blocks
}

resource "aws_security_group_rule" "eb-sg-rule2" {
  for_each          = var.elasticbeanstalk_tier == "Worker" ? local.egress_rules : {}
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  security_group_id = join("", aws_security_group.eb-sg[*].id)
  cidr_blocks       = each.value.cidr_blocks
}