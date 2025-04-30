data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_route53_zone" "main" {
  name         = var.domainname
  private_zone = false
}



locals {
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
  azs        = tolist(slice(data.aws_availability_zones.available.names, 0, 3))
  tags = {
    env_prefix = var.env_prefix
    company    = "devopx"
  }
  ingress_rules = {
    port443 = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    port80 = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress_rules = {
    port80egress = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(
    local.tags,
    {
      "Name" = "${local.tags.env_prefix}-vpc"
    }
  )
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(local.azs, count.index)
  map_public_ip_on_launch = true
  tags = merge(
    local.tags,
    {
      Name = "${local.tags.env_prefix}-public-subnet-${count.index + 1}",
    }
  )
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(local.azs, count.index)
  tags = merge(
    local.tags,
    {
      Name = "${local.tags.env_prefix}-private-subnet-${count.index + 1}"
    }
  )
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    local.tags,
    {
      Name = "${local.tags.env_prefix}-${aws_vpc.main.id}-igw"
    }
  )
}

# Enable components in public subnet to access the Internet
resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(
    local.tags,
    {
      Name = "${local.tags.env_prefix}-public"
    }
  )
  lifecycle {
    ignore_changes = [route]
  }
}

# Associate public subnets to the second table
resource "aws_route_table_association" "public_subnet_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_subnet_route_table.id
}

resource "aws_eip" "nat_gateway" {
  tags = merge(
    local.tags,
    {
      "Name" = "${local.tags.env_prefix}-eip"
    }
  )
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_subnets[0].id
  tags = merge(
    local.tags,
    {
      "Name" = "${local.tags.env_prefix}-nat-gw"
    }
  )
}

resource "aws_route_table" "nat_gateway" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.tags.env_prefix}-private"
    }
  )
  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route_table_association" "nat_gateway" {
  count          = length(aws_subnet.private_subnets[*].id)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.nat_gateway.id
}

# terraform code to create an application ELB
resource "aws_lb" "elb" {
  name                       = "${var.project_name}-elb-${local.tags.env_prefix}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.elb-sg.id]
  subnets                    = aws_subnet.public_subnets[*].id
  enable_deletion_protection = true
  enable_http2               = true
  idle_timeout               = 60
  tags = merge(
    local.tags,
    {
      "Name" = "${var.project_name}-elb"
    }
  )
  lifecycle {
    ignore_changes = [tags, security_groups]
  }
}

resource "aws_security_group" "elb-sg" {
  vpc_id = aws_vpc.main.id
  name   = "${var.project_name}-elb-sg"
  tags   = local.tags
}

resource "aws_security_group_rule" "elb-sg-rule" {
  for_each          = local.ingress_rules
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  security_group_id = aws_security_group.elb-sg.id
  cidr_blocks       = each.value.cidr_blocks
}

resource "aws_security_group_rule" "elb-sg-egress-rule" {
  for_each          = local.egress_rules
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  security_group_id = aws_security_group.elb-sg.id
  cidr_blocks       = each.value.cidr_blocks

}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.elb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  tags = local.tags
}

#create acm certificate
# Request an SSL certificate for the domain via AWS ACM
resource "aws_acm_certificate" "api_cert" {
  domain_name       = "sync-demo-${var.env_prefix}.${var.domainname}"
  validation_method = "DNS"

  # Alternative names (if needed)
  subject_alternative_names = ["*.sync-demo-${var.env_prefix}.${var.domainname}"]

  tags = {
    Name = "${var.env_prefix}.${var.domainname}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Route53 DNS validation record for the ACM certificate
resource "aws_route53_record" "api_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}


resource "aws_acm_certificate_validation" "api_cert_validation" {
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.api_cert_validation : record.fqdn]
}

# terraform code to create 443 listener
resource "aws_alb_listener" "alb_listener_443" {
  load_balancer_arn = aws_lb.elb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.api_cert_validation.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb_target_group.arn
  }
  tags = local.tags
}

resource "aws_alb_target_group" "alb_target_group" {
  name                 = "${var.project_name}-alb-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 120
  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
  }
}

# #tfsec:ignore:aws-ec2-no-public-egress-sgr
# module "fck-nat" {
#   source               = "RaJiska/fck-nat/aws"
#   name                 = "${local.tags.env_prefix}-fck-nat"
#   vpc_id               = aws_vpc.main.id
#   subnet_id            = element(aws_subnet.public_subnets[*].id, 0)
#   ha_mode              = true # Enables high-availability mode
#   use_cloudwatch_agent = false # Enables Cloudwatch agent and have metrics reported
#   update_route_tables  = true
#   instance_type        = "t4g.nano"
#   route_tables_ids = {
#     "our-rtb-name-A" = "${aws_route_table.nat_gateway.id}"
#   }

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }

