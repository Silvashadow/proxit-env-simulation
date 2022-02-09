data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  sum_of_azs = length(data.aws_availability_zones.available.names)
}

resource "aws_vpc" "VPC" {
  cidr_block       = var.main_settings.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "${terraform.workspace}-VPC"
  }
}

resource "aws_subnet" "PublicSubnet" {
  count                   = length(var.main_settings.public_subnet_cidr)
  availability_zone       = data.aws_availability_zones.available.names[count.index % (local.sum_of_azs)]
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = var.main_settings.public_subnet_cidr[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${terraform.workspace}-PublicSubnet${count.index + 1}"
  }
}

resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "${terraform.workspace}-PublicRouteTable"
  }
}

resource "aws_route_table_association" "PublicSubnetRouteTableAssociation" {
  count          = length(var.main_settings.public_subnet_cidr)
  subnet_id      = aws_subnet.PublicSubnet[count.index].id
  route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_internet_gateway" "InternetGateway" {
  vpc_id     = aws_vpc.VPC.id
  depends_on = [aws_vpc.VPC]
  tags = {
    Name = "${terraform.workspace}-InternetGateway"
  }
}

resource "aws_route" "PublicRoute" {
  gateway_id             = aws_internet_gateway.InternetGateway.id
  route_table_id         = aws_route_table.PublicRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_internet_gateway.InternetGateway]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.VPC.id
  service_name = "com.amazonaws.us-east-1.s3"

}
# associate route table with VPC endpoint
resource "aws_vpc_endpoint_route_table_association" "route_table_association" {
  route_table_id  = aws_route_table.PublicRouteTable.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

///////////////////////////////////////////////////////////////////////////////////////
/* CODE Below Is For Ceeating PRIVATE Subnets,Route-Tables/Assosiation,NAT Gateway */
///////////////////////////////////////////////////////////////////////////////////////

resource "aws_subnet" "PrivateSubnet" {
  count             = length(var.main_settings.private_subnet_cidr)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.VPC.id
  cidr_block        = var.main_settings.private_subnet_cidr[count.index]
  tags = {
    Name = "${terraform.workspace}-PrivateSubnet${count.index + 1}"
  }
}

resource "aws_eip" "ElasticIPAddress" {
  vpc        = true
  depends_on = [aws_internet_gateway.InternetGateway]
}

resource "aws_nat_gateway" "NATGateway" {
  allocation_id = aws_eip.ElasticIPAddress.id
  subnet_id     = aws_subnet.PublicSubnet[0].id

  tags = {
    Name = "${terraform.workspace}-NATGateway"
  }
}

resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.VPC.id
  tags = {
    Name = "${terraform.workspace}-PrivateRouteTable"
  }
}

resource "aws_route" "PrivateRoute" {
  gateway_id             = aws_nat_gateway.NATGateway.id
  route_table_id         = aws_route_table.PrivateRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_nat_gateway.NATGateway]
}

resource "aws_route_table_association" "PrivateSubnetRouteTableAssociation" {
  count          = length(var.main_settings.private_subnet_cidr)
  subnet_id      = aws_subnet.PrivateSubnet[count.index].id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

