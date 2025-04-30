output "elasticbeanstalk_app_name" {
  value = join("", aws_elastic_beanstalk_application.app[*].name)
}

output "elasticbeanstalk_cname" {
  value = aws_elastic_beanstalk_environment.aws-elastic-beanstalk-environment.cname
}

output "elasticbeanstalk_endpoint_url" {
  value = aws_elastic_beanstalk_environment.aws-elastic-beanstalk-environment.endpoint_url
}

output "elasticbeanstalk_service_role" {
  value = join("", aws_iam_role.service[*].name)
}

output "elasticbeanstalk_instance_profile" {
  value = join("", aws_iam_instance_profile.ec2[*].name)
}

output "aws_sns_topic_subscription_arns" {
  #value = values(aws_sns_topic_subscription.sns_topic_sub)[*].arn 
  value = { for k, v in aws_sns_topic_subscription.sns_topic_sub : k => v.arn }
}
