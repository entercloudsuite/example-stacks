### Simple Ubuntu 16.04 VM

resource "openstack_compute_instance_v2" "simple-vm" {
  name            = "simple-tf-vm"
  region          = "${var.region}"
  count           = 1
  image_id        = "6a1e4c2b-d663-492a-a828-205f4b28d9e0"
  flavor_name     = "e3standard.x2"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["default"]

  network {
    uuid = "${openstack_networking_network_v2.production-internal-network.id}"
  }

}
