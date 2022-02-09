output "vpc_output" {
  value = {
    vpc_id         = aws_vpc.VPC.id
    public_subnet  = aws_subnet.PublicSubnet.*
    private_subnet = aws_subnet.PrivateSubnet.*.id
    route_table_id = aws_route_table.PublicRouteTable.id

  }
}
