resource "aws_s3_bucket" "bucket" {
  bucket = var.main_settings.bucket_name
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "VPC_EndPoint_test"
  }
}