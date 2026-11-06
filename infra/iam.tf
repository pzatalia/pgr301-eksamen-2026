data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${var.project_name}-task-role-${var.kandidatnummer}"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

data "aws_iam_policy_document" "task_permission" {
  statement {
    sid       = "S3Images"
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.images.arn}/*"]
  }

  statement {
    sid       = "Rekognition"
    actions   = ["rekognition:DetectLabels"]
    resources = ["*"]
  }

  statement {
    sid     = "Bedrock"
    actions = ["bedrock:InvokeModel"]
    resources = [
      "arn:aws:bedrock:*::foundation-model/anthropic.claude-sonnet-4-5*",
      "arn:aws:bedrock:${var.region}:*:inference-profile/eu.anthropic.claude-sonnet-4-5*"
    ]
  }

  statement {
    sid       = "CloudWatchMetrics"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }

}

resource "aws_iam_role_policy" "task_policy" {
  name   = "${var.project_name}-task-policy-${var.kandidatnummer}"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_permission.json

}