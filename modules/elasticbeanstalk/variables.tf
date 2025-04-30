variable "enabled" {
  description = "Create Elastic Beanstalk application"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}
variable "private_subnet_ids" {
  description = "The IDs of the private subnets"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "The IDs of the public subnets"
  type        = list(string)
}
variable "elasticbeanstalk_app_name" {
  description = "The name of the Elastic Beanstalk application"
  type        = string
  default     = "devopx-sync"
}

variable "env_prefix" {
  description = "The prefix for the environment"
  type        = string
}


variable "shared_loadbalancer_arn" {
  description = "The ARN of the shared load balancer"
  type        = string

}

variable "elasticbeanstalk_tier" {
  description = "The tier of the Elastic Beanstalk environment"
  type        = string
  default     = "WebServer"
}

variable "environment_type" {
  type        = string
  default     = "LoadBalanced"
  description = "Environment type, e.g. 'LoadBalanced' or 'SingleInstance'.  If setting to 'SingleInstance', `rolling_update_type` must be set to 'Time', `updating_min_in_service` must be set to 0, and `loadbalancer_subnets` will be unused (it applies to the ELB, which does not exist in SingleInstance environments)"
}

variable "elb_scheme" {
  type        = string
  default     = "public"
  description = "Specify `internal` if you want to create an internal load balancer in your Amazon VPC so that your Elastic Beanstalk application cannot be accessed from outside your Amazon VPC"
}

variable "autoscale_min" {
  type        = number
  default     = 1
  description = "Minumum instances to launch"
}

variable "autoscale_max" {
  type        = number
  default     = 3
  description = "Maximum instances to launch"
}

variable "solution_stack_name" {
  type        = string
  description = "Elastic Beanstalk stack, e.g. Docker, Go, Node, Java, IIS. For more info, see https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html"
  default     = "64bit Amazon Linux 2023 v4.6.1 running PHP 8.2"
}

variable "scheduled_actions" {
  type = list(object({
    name            = string
    minsize         = string
    maxsize         = string
    desiredcapacity = string
    starttime       = string
    endtime         = string
    recurrence      = string
    suspend         = bool
  }))
  default     = []
  description = "Define a list of scheduled actions"
}

variable "healthcheck_httpcodes_to_match" {
  type        = list(string)
  default     = ["200"]
  description = "List of HTTP codes that indicate that an instance is healthy. Note that this option is only applicable to environments with a network or application load balancer"
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.small, t3.large, m4.large"]
  description = "Instances type"
}

variable "enable_spot_instances" {
  type        = bool
  default     = true
  description = "Enable Spot Instance requests for your environment"
}

variable "spot_fleet_on_demand_base" {
  type        = number
  default     = 0
  description = "The minimum number of On-Demand Instances that your Auto Scaling group provisions before considering Spot Instances as your environment scales up. This option is relevant only when enable_spot_instances is true."
}

variable "spot_fleet_on_demand_above_base_percentage" {
  type        = number
  default     = -1
  description = "The percentage of On-Demand Instances as part of additional capacity that your Auto Scaling group provisions beyond the SpotOnDemandBase instances. This option is relevant only when enable_spot_instances is true."
}

variable "spot_max_price" {
  type        = number
  default     = -1
  description = "The maximum price per unit hour, in US$, that you're willing to pay for a Spot Instance. This option is relevant only when enable_spot_instances is true. Valid values are between 0.001 and 20.0"
}

variable "deployment_batch_size_type" {
  type        = string
  default     = "Percentage"
  description = "The type of the deployment batch size. Valid values are `Fixed` or `Percentage`"

}

variable "enable_capacity_rebalancing" {
  type        = bool
  default     = true
  description = "Enable capacity rebalancing. Capacity rebalancing is used to redistribute the load of your instances across the Availability Zones in your environment"
}

variable "enhanced_reporting_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable \"enhanced\" health reporting for this environment.  If false, \"basic\" reporting is used.  When you set this to false, you must also set `enable_managed_actions` to false"
}

variable "managed_actions_enabled" {
  type        = bool
  default     = true
  description = "Enable managed platform updates. When you set this to true, you must also specify a `PreferredStartTime` and `UpdateLevel`"
}

variable "keypair" {
  type        = string
  description = "The EC2 key pair to associate with the instances"
  default     = "devopx-admin"
}

variable "rolling_update_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable rolling update"
}

variable "rolling_update_type" {
  type        = string
  default     = "Health"
  description = "`Health` or `Immutable`. Set it to `Immutable` to apply the configuration change to a fresh group of instances"
}

variable "deployment_policy" {
  type        = string
  default     = "Rolling"
  description = "Use the DeploymentPolicy option to set the deployment type. The following values are supported: `AllAtOnce`, `Rolling`, `RollingWithAdditionalBatch`, `Immutable`, `TrafficSplitting`"
}

variable "deployment_batch_size" {
  type        = string
  default     = "30"
  description = "batch size percentage per deployment"
}

variable "updating_min_in_service" {
  type        = number
  default     = 0
  description = "Minimum number of instances in service during update"
}

variable "updating_max_batch" {
  type        = number
  default     = 2
  description = "Maximum number of instances to update at once"
}

variable "php_settings" {
  type        = map(string)
  default     = {}
  description = "A map of PHP settings"
}

variable "cloudwatch_logs" {
  type        = map(string)
  default     = {}
  description = "A map of CloudWatch logs settings"
}

variable "root_volume_size" {
  type        = number
  default     = 8
  description = "The size of the root volume in gigabytes"
}

variable "preferred_start_time" {
  type        = string
  default     = "Tue:01:00"
  description = "The preferred start time for the maintenance window"
}

variable "instance_refresh_enabled" {
  type        = bool
  default     = true
  description = "Enable instance refresh"
}

variable "update_level" {
  type        = string
  default     = "patch"
  description = "The level of update to apply with managed platform updates. Valid values are `minor` or `patch`"

}


variable "autoscale_measure_name" {
  type        = string
  default     = "CPUUtilization"
  description = "Metric used for your Auto Scaling trigger"
}

variable "autoscale_statistic" {
  type        = string
  default     = "Average"
  description = "Statistic the trigger should use, such as Average"
}

variable "autoscale_unit" {
  type        = string
  default     = "Percent"
  description = "Unit for the trigger measurement, such as Bytes"
}

variable "autoscale_lower_bound" {
  type        = number
  default     = 3
  description = "Minimum level of autoscale metric to remove an instance"
}

variable "autoscale_lower_increment" {
  type        = number
  default     = -1
  description = "How many Amazon EC2 instances to remove when performing a scaling activity."
}

variable "autoscale_upper_bound" {
  type        = number
  default     = 90
  description = "Maximum level of autoscale metric to add an instance"
}

variable "autoscale_upper_increment" {
  type        = number
  default     = 1
  description = "How many Amazon EC2 instances to add when performing a scaling activity"
}

variable "prefer_legacy_service_policy" {
  type        = bool
  default     = false
  description = "Whether to use AWSElasticBeanstalkService (deprecated) or AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy policy"
}

variable "prefer_legacy_ssm_policy" {
  type        = bool
  default     = false
  description = "Whether to use AWSElasticBeanstalkManagedUpdatesServiceRolePolicy (deprecated) or AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy policy"
}

variable "create_eb_app_version" {
  type        = bool
  default     = true
  description = "Create Elastic Beanstalk application version"
}

variable "ec2_instance_profile" {
  type        = string
  description = "The name of the instance profile"
}

variable "eb_service_role_name" {
  type        = string
  description = "The service role for Elastic Beanstalk"
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "A map of environment variables"
}

variable "env_vars_secret_id" {
  type        = string
  description = "The name  of the Secrets Manager secret to use for environment variables"
}

variable "extended_ec2_policy_document" {
  type        = string
  description = "An additional policy to attach to the EC2 instance profile"
  default     = ""
}

variable "notification_email" {
  type        = string
  description = "The email address to notify when the environment status changes"
  default     = "kagodarog@gmail.com"
}

variable "domain_name" {
  type        = string
  description = "The domain name to use for the environment"
  default     = "staging.devopx.com"
}

variable "cidr_blocks" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "port443rulename" {
  type    = string
  default = "443rules"
}

variable "shared_lb_listener_priority" {
  type        = number
  default     = 50
  description = "The priority of the listener rule"
}

variable "eventbridge_filtered_eb_alert_email" {
  type        = list(string)
  default     = ["support@devopx.com", "kagodarog@gmail.com"]
  description = "email address to receive notifications from Elastic Beanstalk"
}