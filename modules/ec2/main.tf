resource "aws_iam_role" "test_role" {
  name               = "test_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "${terraform.workspace}-EC2"
  }
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.test_role.name
}

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = aws_iam_role.test_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1638479619086",
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_instance" "ec2" {
  key_name                    = "aws-devops-terraform"
  ami                         = var.main_settings.ec2_ami
  instance_type               = var.main_settings.ec2_instance_type
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.test_profile.name
  vpc_security_group_ids      = [var.sg_details.ec2_sg_id]
  subnet_id                   = var.vpc_details
  user_data                   = file("${path.module}/userDataScript/ec2Userdata.sh")
  tags = {
    Name = "${terraform.workspace}-EC2"
  }
}
