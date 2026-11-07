# Default VPC та його публічні підсеті (MapPublicIpOnLaunch = true)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

locals {
  # У default VPC всі підсеті публічні та мають маршрут до Internet Gateway
  public_subnet_ids = sort(data.aws_subnets.public.ids)
}
