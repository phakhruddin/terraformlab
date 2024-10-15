# Root configuration calling the module for different business units

module "finance" {
  source         = "./modules/local_file_module"
  business_unit  = "Finance"
  file_content   = "Hello Finance team! This is your dedicated file."
}

module "marketing" {
  source         = "./modules/local_file_module"
  business_unit  = "Marketing"
  file_content   = "Hello Marketing team! This is your dedicated file."
}

module "engineering" {
  source         = "./modules/local_file_module"
  business_unit  = "Engineering"
  file_content   = "Hello Engineering team! This is your dedicated file."
}
