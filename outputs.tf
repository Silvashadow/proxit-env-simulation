output "output_data" {
  value = {
    vpc_id           = module.vpc.vpc_output.vpc_id
    public_subnet_id = module.vpc.vpc_output.public_subnet.*.id
  }
}
