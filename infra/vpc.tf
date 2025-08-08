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
  availability_zone = "us-east-1${element(tolist(["a", "b"]), count.index)}"

  tags = {
    Name = "devsecops-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index + 3}.0/24"
  availability_zone = "us-east-1${element(tolist(["a", "b"]), count.index)}"

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



resource "aws_s3_bucket_policy" "vpc_flow_logs_bucket_policy" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  policy = data.aws_iam_policy_document.vpc_flow_logs_bucket_policy.json
}

data "aws_iam_policy_document" "vpc_flow_logs_bucket_policy" {
  statement {
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.vpc_flow_logs_bucket.arn]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }

  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.vpc_flow_logs_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_s3_bucket.vpc_flow_logs_bucket.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.public.id]
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.sts"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.main.id]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.main.id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.main.id]
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.ec2"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.main.id]
}

resource "aws_security_group" "main" {
  name        = "devsecops-vpc-endpoint-sg"
  description = "Security group for VPC endpoints. Allows HTTPS traffic from within the VPC."
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTPS from within the VPC for endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow all outbound traffic for endpoints to connect to AWS services"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devsecops-vpc-endpoint-sg"
  }
}