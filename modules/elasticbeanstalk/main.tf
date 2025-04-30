data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  tags = {
    env_prefix = var.env_prefix
    company    = "devopx"
  }
  ingress_rules = {
    port443 = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.cidr_blocks
    }
    port80 = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.cidr_blocks
    }
  }
  egress_rules = {
    sgegress = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

###=========================== Service role ========================== ###
data "aws_iam_policy_document" "service" {
  count = var.enabled ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "service" {
  count = var.enabled ? 1 : 0
  assume_role_policy = join("", data.aws_iam_policy_document.service[*].json)
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "enhanced_health" {
  count = var.enabled && var.enhanced_reporting_enabled ? 1 : 0
  role       = join("", aws_iam_role.service[*].name)
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "service" {
  count = var.enabled ? 1 : 0
  role       = join("", aws_iam_role.service[*].name)
  policy_arn = var.prefer_legacy_service_policy ? "arn:${local.partition}:iam::aws:policy/service-role/AWSElasticBeanstalkService" : "arn:${local.partition}:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}


###=========================== EC2 role ========================== ###
data "aws_iam_policy_document" "ec2" {
  count = var.enabled ? 1 : 0

  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }

  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "elastic_beanstalk_multi_container_docker" {
  count = var.enabled ? 1 : 0
  role       = join("", aws_iam_role.ec2[*].name)
  policy_arn = "arn:${local.partition}:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role" "ec2" {
  count = var.enabled ? 1 : 0
  assume_role_policy = join("", data.aws_iam_policy_document.ec2[*].json)
  tags               = local.tags
}

resource "aws_iam_role_policy" "default" {
  count  = var.enabled ? 1 : 0
  role   = join("", aws_iam_role.ec2[*].id)
  policy = join("", data.aws_iam_policy_document.extended[*].json)
}

resource "aws_iam_role_policy_attachment" "web_tier" {
  count = var.enabled ? 1 : 0

  role       = join("", aws_iam_role.ec2[*].name)
  policy_arn = "arn:${local.partition}:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "worker_tier" {
  count = var.enabled ? 1 : 0

  role       = join("", aws_iam_role.ec2[*].name)
  policy_arn = "arn:${local.partition}:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "ssm_ec2" {
  count = var.enabled ? 1 : 0

  role       = join("", aws_iam_role.ec2[*].name)
  policy_arn = var.prefer_legacy_ssm_policy ? "arn:${local.partition}:iam::aws:policy/service-role/AmazonEC2RoleforSSM" : "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "ssm_automation" {
  count = var.enabled ? 1 : 0

  role       = join("", aws_iam_role.ec2[*].name)
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonSSMAutomationRole"

  lifecycle {
    create_before_destroy = true
  }
}

# http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker.container.console.html
# http://docs.aws.amazon.com/AmazonECR/latest/userguide/ecr_managed_policies.html#AmazonEC2ContainerRegistryReadOnly
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  count = var.enabled ? 1 : 0
  role       = join("", aws_iam_role.ec2[*].name)
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_ssm_activation" "ec2" {
  count = var.enabled ? 1 : 0
  iam_role           = join("", aws_iam_role.ec2[*].id)
  registration_limit = var.autoscale_max
  tags               = local.tags
  depends_on         = [aws_elastic_beanstalk_environment.aws-elastic-beanstalk-environment]
}

data "aws_iam_policy_document" "default" {
  count = var.enabled ? 1 : 0

  statement {
    actions = [
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetHealth",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:GetConsoleOutput",
      "ec2:AssociateAddress",
      "ec2:DescribeAddresses",
      "ec2:DescribeSecurityGroups",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeNotificationConfigurations",
    ]

    resources = ["*"]

    effect = "Allow"
  }

  statement {
    sid = "AllowOperations"

    actions = [
      "autoscaling:AttachInstances",
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:CreateLaunchConfiguration",
      "autoscaling:DeleteLaunchConfiguration",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DeleteScheduledAction",
      "autoscaling:DescribeAccountLimits",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeLoadBalancers",
      "autoscaling:DescribeNotificationConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeScheduledActions",
      "autoscaling:DetachInstances",
      "autoscaling:PutScheduledUpdateGroupAction",
      "autoscaling:ResumeProcesses",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:SetInstanceProtection",
      "autoscaling:SuspendProcesses",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "cloudwatch:PutMetricAlarm",
      "ec2:AssociateAddress",
      "ec2:AllocateAddress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DisassociateAddress",
      "ec2:ReleaseAddress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:TerminateInstances",
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:DescribeClusters",
      "ecs:RegisterTaskDefinition",
      "elasticbeanstalk:*",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "iam:ListRoles",
      "logs:CreateLogGroup",
      "logs:PutRetentionPolicy",
      "rds:DescribeDBEngineVersions",
      "rds:DescribeDBInstances",
      "rds:DescribeOrderableDBInstanceOptions",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "sns:CreateTopic",
      "sns:GetTopicAttributes",
      "sns:ListSubscriptionsByTopic",
      "sns:Subscribe",
      "sns:Publish",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "codebuild:CreateProject",
      "codebuild:DeleteProject",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]

    effect = "Allow"
  }

  statement {
    sid = "AllowPassRole"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      join("", aws_iam_role.ec2[*].arn),
      join("", aws_iam_role.service[*].arn)
    ]

    effect = "Allow"
  }

  statement {
    sid = "AllowS3OperationsOnElasticBeanstalkBuckets"

    actions = [
      "s3:*"
    ]

    resources = [
      #bridgecrew:skip=BC_AWS_IAM_57:Skipping "Ensure IAM policies does not allow write access without constraint"
      #bridgecrew:skip=BC_AWS_IAM_56:Skipping "Ensure IAM policies do not allow permissions management / resource exposure without constraint"
      #bridgecrew:skip=BC_AWS_IAM_55:Skipping "Ensure IAM policies do not allow data exfiltration"
      "arn:${local.partition}:s3:::*"
    ]

    effect = "Allow"
  }

  statement {
    sid = "AllowDeleteCloudwatchLogGroups"

    actions = [
      "logs:DeleteLogGroup"
    ]

    resources = [
      "arn:${local.partition}:logs:*:*:log-group:/aws/elasticbeanstalk*"
    ]

    effect = "Allow"
  }

  statement {
    sid = "AllowCloudformationOperationsOnElasticBeanstalkStacks"

    actions = [
      "cloudformation:*"
    ]

    resources = [
      "arn:${local.partition}:cloudformation:*:*:stack/awseb-*",
      "arn:${local.partition}:cloudformation:*:*:stack/eb-*"
    ]

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "extended" {
  count                     = var.enabled ? 1 : 0
  source_policy_documents   = [join("", data.aws_iam_policy_document.default[*].json)]
  override_policy_documents = [var.extended_ec2_policy_document]
}

resource "aws_iam_instance_profile" "ec2" {
  count = var.enabled ? 1 : 0
  role  = join("", aws_iam_role.ec2[*].name)
  tags  = local.tags
}

###=========================== Elastic Beanstalk ========================== ###

# resource "aws_elastic_beanstalk_application_version" "default" {
#   count       = var.elasticbeanstalk_tier == "WebServer" ? 1 : 0
#   name        = "${local.tags.env_prefix}-tf-test-version-label"
#   application = var.create_eb_app_version == false ? var.elasticbeanstalk_app_name : join("", aws_elastic_beanstalk_application.app[*].name)
#   description = "application version created by terraform"
#   bucket      = "tftest-devopx"
#   key         = "beanstalk/php8.2-036d86e-back.zip"
#   lifecycle {
#     ignore_changes = [key]

#   }
# }

resource "aws_elastic_beanstalk_application" "app" {
  count = var.create_eb_app_version ? 1 : 0
  name  = var.elasticbeanstalk_app_name
}

# create elastic beanstalk environment
resource "aws_elastic_beanstalk_environment" "aws-elastic-beanstalk-environment" {
  name                = var.elasticbeanstalk_tier == "WebServer" ? "${var.elasticbeanstalk_app_name}-${var.env_prefix}" : "${var.elasticbeanstalk_app_name}-${var.env_prefix}-wrk"
  application         = var.create_eb_app_version == false ? var.elasticbeanstalk_app_name : join("", aws_elastic_beanstalk_application.app[*].name)
  solution_stack_name = var.solution_stack_name
  tier                = var.elasticbeanstalk_tier
  tags                = local.tags


  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = var.enabled == true ? join("", aws_iam_instance_profile.ec2[*].name) : var.ec2_instance_profile
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = var.enabled == true ? join("", aws_iam_role.service[*].name) : var.eb_service_role_name
    resource  = ""
  }

  dynamic "setting" {
    for_each = var.php_settings
    content {
      namespace = "aws:elasticbeanstalk:container:php:phpini"
      name      = setting.key
      value     = setting.value
      resource  = ""
    }
  }

  dynamic "setting" {
    for_each = var.cloudwatch_logs
    content {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs"
      name      = setting.key
      value     = setting.value
      resource  = ""
    }
  }


  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
    resource  = ""
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", sort(var.private_subnet_ids))
    resource  = ""
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = var.enabled == false ? aws_security_group.eb-sg[0].id : ""
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = var.managed_actions_enabled ? "true" : "false"
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = var.preferred_start_time
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = var.update_level
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "InstanceRefreshEnabled"
    value     = var.instance_refresh_enabled
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SSHSourceRestriction"
    value     = "tcp,22,22,10.0.0.0/16"
    resource  = ""
  }

  setting {
    name      = "Unit"
    namespace = "aws:autoscaling:trigger"
    value     = "Percent"
    resource  = ""
  }
  setting {
    name      = "MeasureName"
    namespace = "aws:autoscaling:trigger"
    value     = "CPUUtilization"
    resource  = ""
  }
  setting {
    name      = "LowerThreshold"
    namespace = "aws:autoscaling:trigger"
    value     = "3"
    resource  = ""
  }
  setting {
    name      = "UpperThreshold"
    namespace = "aws:autoscaling:trigger"
    value     = "80"
    resource  = ""
  }
  setting {
    name      = "Period"
    namespace = "aws:autoscaling:trigger"
    value     = "5"
    resource  = ""
  }
  setting {
    name      = "UpperBreachScaleIncrement"
    namespace = "aws:autoscaling:trigger"
    value     = "1"
    resource  = ""
  }
  setting {
    name      = "LowerBreachScaleIncrement"
    namespace = "aws:autoscaling:trigger"
    value     = "-1"
    resource  = ""
  }

  setting {
    name      = "Notification Endpoint"
    namespace = "aws:elasticbeanstalk:sns:topics"
    value     = var.notification_email
    resource  = ""
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = var.environment_type == "LoadBalanced" ? var.elb_scheme : ""
    resource  = ""
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = false
    resource  = ""
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = var.autoscale_min
    resource  = ""
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.autoscale_max
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "EnableCapacityRebalancing"
    value     = var.enable_capacity_rebalancing
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = var.rolling_update_enabled
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = var.rolling_update_type
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MinInstancesInService"
    value     = var.updating_min_in_service
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = var.deployment_policy
    resource  = ""

  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MaxBatchSize"
    value     = var.updating_max_batch
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = var.deployment_batch_size_type
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = var.deployment_batch_size
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerIsShared"
    value     = true
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
    resource  = ""
  }
  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SharedLoadBalancer"
    value     = var.shared_loadbalancer_arn
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = join(",", sort(var.healthcheck_httpcodes_to_match))
    resource  = ""
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Rules"
    value     = var.enabled == true ? var.port443rulename : ""
    resource  = ""
  }

  setting {
    namespace = "aws:elbv2:listenerrule:${var.port443rulename}"
    name      = "PathPatterns"
    value     = var.enabled == true ? "/*" : ""
    resource  = ""
  }

  setting {
    namespace = "aws:elbv2:listenerrule:${var.port443rulename}"
    name      = "HostHeaders"
    value     = var.enabled == true ? var.domain_name : ""
    resource  = ""
  }

  setting {
    namespace = "aws:elbv2:listenerrule:${var.port443rulename}"
    name      = "Priority"
    value     = var.enabled == true ? var.shared_lb_listener_priority : ""
    resource  = ""
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = join(",", var.instance_types)
    resource  = ""
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "EnableSpot"
    value     = var.enable_spot_instances ? "true" : "false"
    resource  = ""
  }

  #   setting {
  #   namespace = "aws:ec2:instances"
  #   name      = "SupportedArchitectures"
  #   value     = "arm64"
  #   resource  = ""
  # }

  setting {
    namespace = "aws:ec2:instances"
    name      = "SpotFleetOnDemandBase"
    value     = var.spot_fleet_on_demand_base
    resource  = ""
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "SpotFleetOnDemandAboveBasePercentage"
    value     = var.spot_fleet_on_demand_above_base_percentage == -1 ? (var.environment_type == "LoadBalanced" ? 70 : 0) : var.spot_fleet_on_demand_above_base_percentage
    resource  = ""
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "SpotMaxPrice"
    value     = var.spot_max_price == -1 ? "" : var.spot_max_price
    resource  = ""

  }

  # setting {
  #   namespace = "aws:autoscaling:launchconfiguration"
  #   name      = "EC2KeyName"
  #   value     = var.keypair
  #   resource  = ""
  # }

  setting {
    namespace = "aws:elasticbeanstalk:environment:proxy"
    name      = "ProxyServer"
    value     = "apache"
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeSize"
    value     = var.root_volume_size
    resource  = ""
  }

  ###=========================== Autoscale trigger ========================== ###

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = var.autoscale_measure_name
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = var.autoscale_statistic
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = var.autoscale_unit
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = var.autoscale_lower_bound
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerBreachScaleIncrement"
    value     = var.autoscale_lower_increment
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = var.autoscale_upper_bound
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperBreachScaleIncrement"
    value     = var.autoscale_upper_increment
    resource  = ""
  }

  ###=========================== Scheduled Actions ========================== ###

  dynamic "setting" {
    for_each = var.scheduled_actions
    content {
      namespace = "aws:autoscaling:scheduledaction"
      name      = "MinSize"
      value     = setting.value.minsize
      resource  = setting.value.name
    }
  }
  dynamic "setting" {
    for_each = var.scheduled_actions
    content {
      namespace = "aws:autoscaling:scheduledaction"
      name      = "MaxSize"
      value     = setting.value.maxsize
      resource  = setting.value.name
    }
  }
  dynamic "setting" {
    for_each = var.scheduled_actions
    content {
      namespace = "aws:autoscaling:scheduledaction"
      name      = "DesiredCapacity"
      value     = setting.value.desiredcapacity
      resource  = setting.value.name
    }
  }
  dynamic "setting" {
    for_each = var.scheduled_actions
    content {
      namespace = "aws:autoscaling:scheduledaction"
      name      = "Recurrence"
      value     = setting.value.recurrence
      resource  = setting.value.name
    }
  }
  dynamic "setting" {
    for_each = var.scheduled_actions
    content {
      namespace = "aws:autoscaling:scheduledaction"
      name      = "StartTime"
      value     = setting.value.starttime
      resource  = setting.value.name
    }
  }
  dynamic "setting" {
    for_each = var.scheduled_actions
    content {
      namespace = "aws:autoscaling:scheduledaction"
      name      = "EndTime"
      value     = setting.value.endtime
      resource  = setting.value.name
    }
  }
  dynamic "setting" {
    for_each = var.scheduled_actions
    content {
      namespace = "aws:autoscaling:scheduledaction"
      name      = "Suspend"
      value     = setting.value.suspend ? "true" : "false"
      resource  = setting.value.name
    }
  }

  ###=========================== Environment Variables ========================== ###
  dynamic "setting" {
    for_each = var.env_vars
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
      resource  = ""
    }
  }

  lifecycle {
    ignore_changes = [solution_stack_name]
  }
}

resource "aws_cloudwatch_event_rule" "elastic_beanstalk_health_alerts" {
  count         = var.elasticbeanstalk_tier == "WebServer" && local.tags.env_prefix == "prod" ? 1 : 0
  description   = "Elastic Beanstalk health alerts"
  event_pattern = <<EOF
{
  "source": ["aws.elasticbeanstalk"],
  "detail-type": ["Health status change"],
  "detail": {
    "Message": [{
      "anything-but": {
      "wildcard": 
        [
        "*Warning*", "*Info*", "*Degraded*"
      ]
      }
    }],
    "Severity": ["INFO","WARN"],
    "EnvironmentName": [
      "${aws_elastic_beanstalk_environment.aws-elastic-beanstalk-environment.name}",
      "${aws_elastic_beanstalk_environment.aws-elastic-beanstalk-environment.name}-wrk"
        ]
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "resource_status_alerts" {
  count          = var.elasticbeanstalk_tier == "WebServer" && local.tags.env_prefix == "prod" ? 1 : 0
  description    = "Elastic Beanstalk Resource Status Alerts."
  event_pattern  = <<EOF
{
  "source": ["aws.elasticbeanstalk"],
  "detail-type": ["Elastic Beanstalk resource status change"],
  "detail": {
      "Message": [{
      "anything-but": {
      "prefix": 
        [
        "Environment update"
      ]
      }
    }],
    "Severity": ["INFO","WARN"],
    "EnvironmentName": [
      "${aws_elastic_beanstalk_environment.aws-elastic-beanstalk-environment.name}",
      "${aws_elastic_beanstalk_environment.aws-elastic-beanstalk-environment.name}-wrk"
    ]
  }
}
EOF
  state          = "ENABLED"
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_rule" "other_resource_status_alerts" {
  count          = var.elasticbeanstalk_tier == "WebServer" && local.tags.env_prefix == "prod" ? 1 : 0
  description    = "Elastic Beanstalk OtherResource Status Alerts.e.g Autoscaling groups"
  event_pattern  = <<EOF
{
  "source": ["aws.elasticbeanstalk"],
  "detail-type": ["Other resource status change"],
  "detail": {
        "Message": [{
      "anything-but": {
      "wildcard": 
        [
        "Warning","*Info*","*Removed*", "*Added*"
      ]
      }
    }],
    "EnvironmentName": [
      "${aws_elastic_beanstalk_environment.aws-elastic-beanstalk-environment.name}",
      "${aws_elastic_beanstalk_environment.aws-elastic-beanstalk-environment.name}-wrk"
    ]
  }
}
EOF
  state          = "ENABLED"
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "sns_target" {
  count = var.elasticbeanstalk_tier == "WebServer" && local.tags.env_prefix == "prod" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.elastic_beanstalk_health_alerts[0].name
  arn   = aws_sns_topic.sns_topic[0].arn
}

resource "aws_cloudwatch_event_target" "sns_target_resources" {
  count = var.elasticbeanstalk_tier == "WebServer" && var.elasticbeanstalk_tier == "WebServer" && local.tags.env_prefix == "prod" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.resource_status_alerts[0].name
  arn   = aws_sns_topic.sns_topic[0].arn
}

resource "aws_cloudwatch_event_target" "sns_target_other_resources" {
  count = var.elasticbeanstalk_tier == "WebServer" && local.tags.env_prefix == "prod" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.other_resource_status_alerts[0].name
  arn   = aws_sns_topic.sns_topic[0].arn
}


# Eventbridge_filtered_eb_alert_SNS
resource "aws_sns_topic" "sns_topic" {
  count        = var.elasticbeanstalk_tier == "WebServer" && local.tags.env_prefix == "prod" ? 1 : 0
  display_name = "devopxEBHealthAlerts"
  tags         = local.tags
}

# sns access policy
resource "aws_sns_topic_policy" "sns_topic_policy" {
  count  = var.elasticbeanstalk_tier == "WebServer" && local.tags.env_prefix == "prod" ? 1 : 0
  arn    = aws_sns_topic.sns_topic[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count     = var.elasticbeanstalk_tier == "WebServer" && local.tags.env_prefix == "prod" ? 1 : 0
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.sns_topic[0].arn,
    ]

    sid = "__default_statement_ID"
  }
}

resource "aws_sns_topic_subscription" "sns_topic_sub" {
  for_each  = var.elasticbeanstalk_tier == "WebServer" && local.tags.env_prefix == "prod" ? toset(var.eventbridge_filtered_eb_alert_email) : []
  topic_arn = aws_sns_topic.sns_topic[0].arn
  protocol  = "email"
  endpoint  = each.value
}