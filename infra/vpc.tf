provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "devsecops-vpc"
  }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index + 1}.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "devsecops-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index + 3}.0/24"

  tags = {
    Name = "devsecops-private-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devsecops-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "devsecops-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_kms_key" "s3_flow_logs_key" {
  description             = "KMS key for S3 VPC Flow Logs bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key" "s3_access_logs_key" {
  description             = "KMS key for S3 VPC Flow Logs Access Logs bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
  bucket = "devsecops-vpc-flow-logs-${aws_vpc.main.id}" # Unique bucket name

  tags = {
    Name = "devsecops-vpc-flow-logs-bucket"
  }
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs_bucket_versioning" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs_bucket_public_access_block" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  block_public_acls   = true
  ignore_public_acls  = true
  block_public_policy = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs_bucket_encryption" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_flow_logs_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "vpc_flow_logs_bucket_logging" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  target_bucket = aws_s3_bucket.vpc_flow_logs_access_log_bucket.id
  target_prefix = "log/"
}



resource "aws_s3_bucket" "vpc_flow_logs_access_log_bucket" {
  bucket = "devsecops-vpc-flow-logs-access-logs-${aws_vpc.main.id}" # Unique bucket name

  tags = {
    Name = "devsecops-vpc-flow-logs-access-log-bucket"
  }
}

resource "aws_s3_bucket_logging" "vpc_flow_logs_access_log_bucket_logging" {
  bucket        = aws_s3_bucket.vpc_flow_logs_access_log_bucket.id
  target_bucket = aws_s3_bucket.vpc_flow_logs_access_log_bucket.id
  target_prefix = "log/access-logs/"
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs_access_log_bucket_versioning" {
  bucket = aws_s3_bucket.vpc_flow_logs_access_log_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs_access_log_bucket_public_access_block" {
  bucket = aws_s3_bucket.vpc_flow_logs_access_log_bucket.id

  block_public_acls   = true
  ignore_public_acls  = true
  block_public_policy = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs_access_log_bucket_encryption" {
  bucket = aws_s3_bucket.vpc_flow_logs_access_log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_access_logs_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_iam_role" "flow_log_role" {
  name = "devsecops-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name = "devsecops-flow-log-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Resource = [
          //tfsec:ignore:aws-iam-no-policy-wildcards
          "${aws_s3_bucket.vpc_flow_logs_bucket.arn}/*",
          aws_s3_bucket.vpc_flow_logs_bucket.arn,
        ]
  })
}

resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_s3_bucket.vpc_flow_logs_bucket.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  iam_role_arn         = aws_iam_role.flow_log_role.arn
}