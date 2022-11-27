terraform {
  backend "s3" {
    bucket = "my-tf-backup-bucket"
    key    = "LockID"
    region = "us-east-1"
  }
}