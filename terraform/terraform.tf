terraform {
  backend "s3" {
    encrypt = true
    bucket = "ncats-terraform-remote-state-storage"
    dynamodb_table = "terraform-state-lock"
    region = "us-east-1"
    key = "orchestrator-codepipeline/terraform.tfstate"
  }
}
