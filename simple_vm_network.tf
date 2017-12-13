### Simple Ubuntu 16.04 VM with its network

resource "openstack_networking_network_v2" "network" {
  name            = "simple-vm-network"
  region          = "${var.region}"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = "simple-vm-network-subnet"
  network_id      = "${openstack_networking_network_v2.network.id}"
  cidr            = "192.168.200.0/24"
  dns_nameservers = ["8.8.8.8"]
  region          = "${var.region}"
}

resource "openstack_networking_router_interface_v2" "router-int" {
  router_id       = "${openstack_networking_router_v2.router.id}"
  subnet_id       = "${openstack_networking_subnet_v2.subnet.id}"
  region          = "${var.region}"
}

resource "openstack_compute_instance_v2" "simple-vm" {
  name            = "simple-tf-vm"
  region          = "${var.region}"
  count           = 1
  image_id        = "6a1e4c2b-d663-492a-a828-205f4b28d9e0"
  flavor_name     = "e3standard.x2"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["default"]

  network {
    uuid = "${openstack_networking_network_v2.network.id}"
  }

}

