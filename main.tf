module "vpc" {
  source = "./modules/vpc"
}

module "security_groups" {
  source     = "./modules/security_groups"
  vpc_id     = module.vpc.vpc_id
  admin_cidr = var.admin_cidr
}


module "load_balancers" {
  source = "./modules/load_balancers"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  public_alb_sg_id  = module.security_groups.public_alb_sg_id
  private_alb_sg_id = module.security_groups.private_alb_sg_id
}


module "ec2" {
  source = "./modules/ec2"

  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  web_sg_id = module.security_groups.web_sg_id
  app_sg_id = module.security_groups.app_sg_id
  db_sg_id  = module.security_groups.db_sg_id

  web_target_group_arn = module.load_balancers.web_target_group_arn
  app_target_group_arn = module.load_balancers.app_target_group_arn

  # Optional: enter your existing EC2 key pair name
  key_name = null
}
