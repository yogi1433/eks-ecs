# # Provider Block
# provider "aws" {
#   region  = "ap-south-1"
#   profile = "sreenivas"
# }

# # Variables
# variable "ecr_repo_name" {
#   description = "Name of the ECR repository"
#   type        = string
#   default     = "python-app"
# }

# # ECR Repository
# resource "aws_ecr_repository" "python_app" {
#   name = var.ecr_repo_name

#   image_scanning_configuration {
#     scan_on_push = true
#   }

#   tags = {
#     Environment = "POC"
#     Team        = "DevOps"
#   }
# }

# # Outputs
# output "ecr_repository_url" {
#   value = aws_ecr_repository.python_app.repository_url
# }

# output "ecr_repository_arn" {
#   value = aws_ecr_repository.python_app.arn
# }

#############################################################################

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

variable "docker_image_path" {
  description = "Path to the directory containing the Dockerfile"
  type        = string
  default     = "/sri-ecr-ecs/docker/python"
}

# ECR Repository
resource "aws_ecr_repository" "python_app" {
  name = var.ecr_repo_name

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
    context    = var.docker_image_path
    dockerfile = "${var.docker_image_path}/Dockerfile"
  }
}

# Output ECR Repository URL
output "ecr_repository_url" {
  value = aws_ecr_repository.python_app.repository_url
}

output "docker_image_url" {
  value = docker_image.python_app.name
}


