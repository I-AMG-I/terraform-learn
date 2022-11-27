resource "aws_ecr_repository" "myapp-ecr" {
  name                 = "${var.env_prefix}-ecr-1"
  image_tag_mutability = "MUTABLE"

}