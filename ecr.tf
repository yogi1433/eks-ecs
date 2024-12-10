terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Docker Provider Configuration
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Variables
variable "my_app_name" {
  description = "Name of the Python ECR repository"
  type        = string
  default     = "my-app-name"
}

# ECR Repository for my_app_name
resource "aws_ecr_repository" "my_app_name" {
  name         = var.my_app_name
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "POC"
    Team        = "DevOps"
  }
}

# Docker Image Build for my_app_name
resource "docker_image" "my_app_name" {
  name = "${aws_ecr_repository.my_app_name.repository_url}:latest"
  build {
    context    = "/var/lib/jenkins/workspace/eks-ecr/eks-ecs/docker/my_web_app"
    dockerfile = "Dockerfile"
  }
}

# ECR Login for my_app_name
resource "null_resource" "docker_ecr_login_my_app_name" {
  provisioner "local-exec" {
    environment = {
      AWS_PROFILE        = "yogesh"  # Use your AWS profile name
      AWS_DEFAULT_REGION = "ap-south-1"
    }
    command = <<EOT
      aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.my_app_name.repository_url}
    EOT
  }
}

# Push the my_app_name Image to ECR
resource "null_resource" "push_my_app_name_to_ecr" {
  depends_on = [
    docker_image.my_app_name,
    null_resource.docker_ecr_login_my_app_name
  ]

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.my_app_name.repository_url}:latest"
  }
}

# Output ECR Repository URLs
output "my_app_name_ecr_repository_url" {
  value = aws_ecr_repository.my_app_name.repository_url
}

# Output Docker Image URLs
output "my_app_name_docker_image_url" {
  value = docker_image.my_app_name.name
}

