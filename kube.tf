variable "slave-count"  { default = "2" }
variable "image_id"     { default = "6a1e4c2b-d663-492a-a828-205f4b28d9e0" }
variable "kube-token"   { default = "7d5134.a64d452ace9c313f" }
variable "access_cidr"  { default = "0.0.0.0/0" }

output "kube-master-ip" { value = "${openstack_compute_floatingip_v2.kube-master.address}" }


resource "openstack_compute_floatingip_v2" "kube-master" {
  region = "${var.region}"
  pool = "PublicNetwork"
}

resource "openstack_compute_secgroup_v2" "kube-master" {
  region = "${var.region}"
  name = "kube-master"
  description = "Kube Master Node"

  # SSH Access
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "${var.access_cidr}"
  }

  # Access to/from Kube Network
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "${var.production-internal-network-cidr}"
  }

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    cidr        = "${var.production-internal-network-cidr}"
  }

  # Access to random ports
  rule {
    from_port   = 30000
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "${var.access_cidr}"
  }

}

resource "openstack_compute_secgroup_v2" "kube-slave" {
  region = "${var.region}"
  name = "kube-slave"
  description = "Kube Slave Nodes"

  # Full Access from local cidr
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "${var.production-internal-network-cidr}"
  }

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    cidr        = "${var.production-internal-network-cidr}"
  }

}

resource "openstack_compute_instance_v2" "kube-master" {
  region = "${var.region}"
  name            = "kube-master"
  image_id        = "${var.image_id}"
  flavor_name     = "e3standard.x3"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  lifecycle {
    ignore_changes = ["user_data"]
  }

  floating_ip = "${openstack_compute_floatingip_v2.kube-master.address}"
  security_groups = ["${openstack_compute_secgroup_v2.kube-master.name}"]
  user_data       = "${data.template_file.cloud-config-master.rendered}"

  network {
    uuid = "${openstack_networking_network_v2.production-internal-network.id}"
  }

}

data "template_file" "cloud-config-master" {
  template = "${file("${path.module}/kube-master.yml")}"
  vars {
    public-ip  = "${openstack_compute_floatingip_v2.kube-master.address}"
    kube-token = "${var.kube-token}"
  }
}

resource "openstack_compute_instance_v2" "kube-slave" {
  region = "${var.region}"
  count    = "${var.slave-count}"
  lifecycle {
    ignore_changes = ["user_data"]
  }

  depends_on      = ["openstack_compute_instance_v2.kube-master"]

  name            = "${format("kube-slave-%02d", count.index + 1)}"
  image_id        = "${var.image_id}"
  flavor_name     = "e3standard.x3"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.kube-slave.name}"]
  user_data       = "${element(data.template_file.cloud-config-slave.*.rendered, count.index)}"

  network {
    uuid = "${openstack_networking_network_v2.production-internal-network.id}"
  }

}

data "template_file" "cloud-config-slave" {
  count = "${var.slave-count}"
  template = "${file("${path.module}/kube-slave.yml")}"

  vars {
    hostname   = "${format("kube-slave-%02d", count.index + 1)}"
    master-ip  = "${openstack_compute_instance_v2.kube-master.network.0.fixed_ip_v4}"
    kube-token = "${var.kube-token}"
  }

}

