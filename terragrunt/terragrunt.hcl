include {
  path = find_in_parent_folders()
}
iam_role = local.account_vars.iam_role

terraform {
    source = "git::https://github.com/iac-module/aws-tgw.git//?ref=v1.0.0"
}

locals {
  common_tags  = read_terragrunt_config(find_in_parent_folders("tags.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region       = local.region_vars.locals.aws_region
  name         = basename(get_terragrunt_dir())
}

dependency "vpc" {
  config_path = find_in_parent_folders("./main")
}

inputs = {

  name                                  = local.name
  description                           = "My TGW Attachment"
  create_tgw                            = false
  share_tgw                             = false
  create_tgw_routes                     = false
  enable_auto_accept_shared_attachments = true

  vpc_attachments = {
    main = {
      tgw_id                                          = local.account_vars.locals.tgw_id
      vpc_id                                          = dependency.vpc.outputs.vpc_id
      subnet_ids                                      = dependency.vpc.outputs.intra_subnets
      dns_support                                     = true
      ipv6_support                                    = false
      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true
      vpc_route_table_ids                             = concat(dependency.vpc.outputs.database_route_table_ids, dependency.vpc.outputs.private_route_table_ids)

      tgw_destination_cidr = local.account_vars.locals.x.vpn_cidr
      tgw_additional_cidrs = [local.account_vars.locals.x.qa_vpc_cidr, local.account_vars.locals.x.prod_vpc_cidr]
    }
  }
  tags = local.common_tags.locals.common_tags
}
