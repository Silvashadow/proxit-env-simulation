output "sg_output" {
  value = {
    ec2_sg_id = aws_security_group.InstanceSecurityGroup.id
  }
}
