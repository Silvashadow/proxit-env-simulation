provider "aws" {
  region = var.settings.AWS_REGION
}

# provider "aws" {
#   alias = "accepter"
#   region  = "${var.region}"
#   profile = "${var.accepter_profile}"
# }
