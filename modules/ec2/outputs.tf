output "ec2_output" {
  value = {
    ec2_id    = aws_instance.ec2.id
    public_ip = aws_instance.ec2.public_ip
  }
}
