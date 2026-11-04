resource "aws_s3_bucket" "images" {
  bucket        = "${var.project_name}-images-${var.kandidatnummer}"
  force_destroy = true
}