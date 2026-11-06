resource "aws_cloudwatch_metric_alarm" "bedrock_slow" {
  alarm_name          = "${var.namespace}-bedrock-latency"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.max_bedrock_ms
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_description = "Varsler når bedrock kallet i snitt tar mer enn ${var.max_bedrock_ms} ms over 5 minutter."
  alarm_actions     = [aws_sns_topic.alarm.arn]

  metric_query {
    id          = "avg_time"
    expression  = "total_time / call_count"
    label       = "Snittid bedrock ms"
    return_data = true
  }

  metric_query {
    id = "total_time"
    metric {
      namespace   = var.namespace
      metric_name = "wishifai.bedrock.latency.sum"
      period      = 300
      stat        = "Sum"
    }
  }

  metric_query {
    id = "call_count"
    metric {
      namespace   = var.namespace
      metric_name = "wishifai.bedrock.latency.count"
      period      = 300
      stat        = "Sum"
    }
  }
}

resource "aws_sns_topic" "alarm" {
  name = "${var.namespace}-alarm-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}