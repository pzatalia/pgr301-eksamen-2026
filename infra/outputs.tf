output "service_url" {
  description = "Offentlig URL til tjenesten"
  value       = aws_ecs_express_gateway_service.wishifai.ingress_paths[0].endpoint
}

output "s3_bucket" {
  description = "Bucket for opplastede bilder"
  value       = aws_s3_bucket.images.bucket
}

output "image" {
  description = "Image som tjenesten kjører"
  value       = "${var.ecr_repository_url}:${var.image_tag}"
}

output "task_role_arn" {
  description = "Task rollen tjenesten bruker"
  value       = aws_iam_role.task_role.arn
}

output "dashboard_name"{
  description = "Navn på Cloudwatch dashboard"
  value = aws_cloudwatch_dashboard.main.dashboard_name
}