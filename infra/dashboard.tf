locals {
  namespace    = "${var.project_name}-${var.kandidatnummer}"
  service_name = aws_ecs_express_gateway_service.wishifai.service_name
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.kandidatnummer}"
  dashboard_body = <<DASHBOARD
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "title": "Business: bilder analysert",
        "region": "${var.region}",
        "metrics": [
          [ "${local.namespace}", "wishifai.gift.suggestions.count", { "label": "Bilder analysert" } ]
        ],
        "period": 300,
        "stat": "Sum",
        "view": "timeSeries"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "title": "Business: snitt gaveforslag per bilde",
        "region": "${var.region}",
        "metrics": [
            [ { "expression": "m2 / m1", "label": "Snitt gaveforslag per bilde", "id": "e1" } ],
            [ "${local.namespace}", "wishifai.gift.suggestions.count", { "id": "m1", "visible": false } ],
            [ "${local.namespace}", "wishifai.gift.suggestions.sum", { "id": "m2", "visible": false } ]
        ],
        "period": 300,
        "stat": "Sum",
        "view": "timeSeries"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "title": "Infrastruktur: CPU (%)",
        "region": "${var.region}",
        "metrics": [
            [ "AWS/ECS", "CPUUtilization", "ServiceName", "${local.service_name}", "ClusterName", "default" ]
        ],
        "stat": "Average",
        "period": 300,
        "view": "timeSeries"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "title": "Infrastruktur: minne (%)",
        "region": "${var.region}",
        "metrics": [
            [ "AWS/ECS", "MemoryUtilization", "ServiceName", "${local.service_name}", "ClusterName", "default" ]
        ],
        "stat": "Average",
        "period": 300,
        "view": "timeSeries"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 12,
      "width": 24,
      "height": 6,
      "properties": {
        "title": "Applikasjon: svartid POST /api/analyze (ms)",
        "region": "${var.region}",
        "metrics": [
          [ "${local.namespace}", "http.server.requests.avg", "uri", "/api/analyze", "method", "POST", "status", "200", "outcome", "SUCCESS", "exception", "none", "error", "none" ]
        ],
        "stat": "Average",
        "period": 300,
        "view": "timeSeries"
      }
    }
  ]
}
DASHBOARD
}

module "alarm" {
  source      = "./alarm_module"
  alarm_email = var.alarm_email
  namespace   = local.namespace
}