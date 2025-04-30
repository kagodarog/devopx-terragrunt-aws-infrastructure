
locals {
  tags = {
    env_prefix = "${var.env_prefix}"
    company    = "devopx"
  }
  ingress_rules = {
    port22 = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    port3306 = {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16", "102.36.218.235/32", "172.31.5.92/32"]
    }
  }
}

# Associate the Elastic IP with the EC2 instance
resource "aws_eip_association" "default" {
  instance_id   = aws_instance.dev_stage_devopx_mysql8.id
  allocation_id = var.eip_allocation_id
}

resource "aws_instance" "dev_stage_devopx_mysql8" {
  ami                         = "ami-0e449927258d45bc4"
  instance_type               = "t3.medium"
  associate_public_ip_address = true
  subnet_id                   = var.instance_subnet_id

  tags = {
    Name       = "dev stage devopx MySQL 8"
    Snapshot   = "true"
    env_prefix = local.tags.env_prefix
  }
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_security_group" "db_sg" {
  vpc_id = var.vpc_id
  name   = "${local.tags.env_prefix}-db-sg"
  tags   = local.tags
}

resource "aws_security_group_rule" "db_sg_rule" {
  for_each          = local.ingress_rules
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.db_sg.id
}