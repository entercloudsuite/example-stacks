# Example VM and security group defined by using EnterCloudSuite terraform modules
# https://github.com/entercloudsuite/terraform-modules

# Create ssh firewall policy
module "demo-instance-ssh-sg" {
  source = "github.com/entercloudsuite/terraform-modules//security?ref=2.6"
  name = "demo-instance-ssh-sg"
  region = "${var.region}"
  protocol = "tcp"
  port_range_min = 22
  port_range_max = 22
  allow_remote = "0.0.0.0/0"
}

# Create instance
module "demo-instance" {
  source = "github.com/entercloudsuite/terraform-modules//instance?ref=2.6"
  name = "demo-instance"
  quantity = 1
  external = "true"
  flavor = "e3standard.x1"
  network_name = "${var.network_name}"
  sec_group = ["${module.demo-instance-ssh-sg.sg_id}"]
  keypair = "${var.keypair_name}"
  tags = {
    "server_group" = "DEMO"
  }
}