# Step 1: AWS Resources and EKS Cluster Setup

# Provider Block for AWS
provider "aws" {
  region  = "ap-south-1"
  profile = "sreenivas"
}

# Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "cicd-cluster"
}

variable "cluster_version" {
  description = "Version of Kubernetes to use in the EKS cluster"
  type        = string
  default     = "1.25"
}

variable "subnet_cidr_blocks" {
  description = "List of subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_types" {
  description = "EC2 instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired number of nodes in the Node Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of nodes in the Node Group"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of nodes in the Node Group"
  type        = number
  default     = 1
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Subnets
data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  count                   = length(var.subnet_cidr_blocks)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_blocks[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# IAM Role for Node Group
resource "aws_iam_role" "node_group" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach IAM Policies to Node Group Role
resource "aws_iam_role_policy_attachment" "node_group_policies" {
  count      = 3
  role       = aws_iam_role.node_group.name
  policy_arn = element([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ], count.index)
}

# EKS Cluster Module
module "eks" {
  source                  = "terraform-aws-modules/eks/aws"
  version                 = "~> 19.0"
  cluster_name            = var.cluster_name
  cluster_version         = var.cluster_version
  vpc_id                  = aws_vpc.main.id
  subnet_ids              = aws_subnet.public[*].id
  create_aws_auth_configmap = false # Disable auto-creation of aws-auth
}

# EKS Node Group
resource "aws_eks_node_group" "worker_nodes" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "worker-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = var.instance_types

  tags = {
    Name = "eks-worker-group"
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
