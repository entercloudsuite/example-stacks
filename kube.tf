module "kubernetes" {
  source 		= "github.com/entercloudsuite/terraform-modules//kubernetes"
  image 		= "ecs-kubernetes"
  region 		= "it-mil1"
  master_flavor		= "e3standard.x2"
  slave_flavor		= "e3standard.x3"
  slave_count 		= 2
  network_uuid 		= "${openstack_networking_network_v2.production-internal-network.id}"
  network-internal-cidr = "${var.production-internal-network-cidr}"
  floating_ip_pool 	= "${var.floating_ip_pool}"
  keyname 		= "${openstack_compute_keypair_v2.keypair.name}"
  pod-network-cidr 	= "192.168.0.0/16"
  service-cidr		= "172.20.0.0/16"
}

