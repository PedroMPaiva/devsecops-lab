terraform {
  backend "s3" {
    bucket         = "devsecops-lab-tfstate-pedrompaiva"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}