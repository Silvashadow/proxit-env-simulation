#######
#VPC
#######

module "vpc" {
  source        = "./modules/vpc"
  main_settings = var.settings
}

###############
#Security-Group
###############

module "SG" {
  source = "./modules/sg"
  vpc_id = module.vpc.vpc_output.vpc_id
}

#####
# EC2
#####

module "ec2" {
  source        = "./modules/ec2"
  main_settings = var.settings
  vpc_details   = module.vpc.vpc_output.public_subnet[0].id
  sg_details    = module.SG.sg_output

}

############
#vpc-peering
############
module "secondvpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "172.30.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["172.30.131.0/24", "172.30.132.0/24", "172.30.133.0/24"]
  public_subnets  = ["172.30.134.0/24", "172.30.135.0/24", "172.30.136.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

  module "vpc-peering" {
      source            = "clouddrove/vpc-peering/aws"
      version           = "0.15.0"
      name              = "vpc-peering"
      environment       = "test"
      label_order       = ["environment", "name", "application"]
      requestor_vpc_id  = module.vpc.vpc_output.vpc_id
      acceptor_vpc_id   = module.secondvpc.vpc_id
    }

###########
#Local-Vars
###########
locals {
  name   = "replica-postgresql"
  region = "us-east-1"
  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  engine                = "postgres"
  engine_version        = "11.10"
  family                = "postgres11" # DB parameter group
  major_engine_version  = "11"         # DB option group
  instance_class        = "db.t2.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  port                  = 5432
}


data "aws_secretsmanager_secret" "secrets" {
  name = "my-postgres-cred"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}
################################################################################
# Master DB
################################################################################

module "master" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${local.name}-master"

  engine               = local.engine
  engine_version       = local.engine_version
  family               = local.family
  major_engine_version = local.major_engine_version
  instance_class       = local.instance_class

  allocated_storage     = local.allocated_storage
  max_allocated_storage = local.max_allocated_storage
  storage_encrypted     = false

  name     = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["my-postgres-cred"]
  username = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["postgres"]
  password = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["postgres123"]
  port     = local.port

  multi_az               = true
  create_db_subnet_group = false
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.id
  vpc_security_group_ids = [module.SG.sg_output.ec2_sg_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Backups are required in order to create a replica
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = local.tags
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds_subnet"
  subnet_ids = module.vpc.vpc_output.private_subnet

  tags = {
    Name = "rds-subnet-group"
  }
}

################################################################################
# Replica DB
################################################################################

module "replica" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${local.name}-replica"

  # Source database. For cross-region use db_instance_arn
  replicate_source_db = module.master.db_instance_id

  engine               = local.engine
  engine_version       = local.engine_version
  family               = local.family
  major_engine_version = local.major_engine_version
  instance_class       = local.instance_class

  allocated_storage     = local.allocated_storage
  max_allocated_storage = local.max_allocated_storage
  storage_encrypted     = false

  # Username and password should not be set for replicas
  username = null
  password = null
  port     = local.port

  multi_az               = false
  vpc_security_group_ids = [module.SG.sg_output.ec2_sg_id]

  maintenance_window              = "Tue:00:00-Tue:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  # Not allowed to specify a subnet group for replicas in the same region
  create_db_subnet_group = false

  tags = local.tags
}

####
# S3
####

module "s3" {
  source        = "./modules/s3"
  main_settings = var.settings
}