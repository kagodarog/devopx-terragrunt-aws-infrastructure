resource "aws_cloudwatch_metric_alarm" "example" {
  alarm_name          = "example-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Latency"
  namespace           = "AWS/Beanstalk"
  period              = 60
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "This metric checks the latency of the Elastic Beanstalk environment"
  alarm_actions       = [aws_sns_topic.example.arn]
  dimensions = {
    EnvironmentName = aws_elastic_beanstalk_environment.example.name
  }
}

resource "aws_sns_topic" "example" {
  name = "example-topic"
}

resource "aws_elastic_beanstalk_environment" "example" {
  name                = "example-environment"
  application         = aws_elastic_beanstalk_application.example.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.0 running Node.js 14"
}

resource "aws_elastic_beanstalk_application" "example" {
  name = "example-application"
}