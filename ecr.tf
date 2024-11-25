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

# AWS Provider Configuration
provider "aws" {
  region  = "ap-south-1"
  profile = "sreenivas"
}

# Docker Provider Configuration
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Variables
variable "ecr_repo_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "python-app"
}

# ECR Repository
resource "aws_ecr_repository" "python_app" {
  name = var.ecr_repo_name
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "POC"
    Team        = "DevOps"
  }
}

# Docker Image Build
resource "docker_image" "python_app" {
  name         = "${aws_ecr_repository.python_app.repository_url}:latest"
  build {
    context    = "/home/latheef/eks-ecs/docker/python"
    dockerfile = "Dockerfile"
  }
}

resource "null_resource" "docker_ecr_login" {
  provisioner "local-exec" {
    environment = {
      "AWS_PROFILE"     = "sreenivas"  # Use your profile name
      "AWS_DEFAULT_REGION" = "ap-south-1"
    }
    command = <<EOT
      aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 0115282                                                                                  65816.dkr.ecr.ap-south-1.amazonaws.com/python-app
    EOT
  }
}






# Authenticate Docker to ECR
#resource "null_resource" "docker_ecr_login" {
 # provisioner "local-exec" {
  #  command = "aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-std                                                                                  in ${aws_ecr_repository.python_app.repository_url}"
 # }
#}

# Push the image to ECR
resource "null_resource" "push_to_ecr" {
  depends_on = [
    docker_image.python_app,
    null_resource.docker_ecr_login
  ]

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.python_app.repository_url}:latest"
  }
}

# Output ECR Repository URL
output "ecr_repository_url" {
  value = aws_ecr_repository.python_app.repository_url
}

# Output Docker Image URL
output "docker_image_url" {
  value = docker_image.python_app.name
}
