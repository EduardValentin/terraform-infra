resource "hcloud_primary_ip" "ipv4" {
  name          = "${var.name}-ipv4"
  datacenter    = var.location
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = false
}

resource "hcloud_primary_ip" "ipv6" {
  name          = "${var.name}-ipv6"
  datacenter    = var.location
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false
}

resource "hcloud_firewall" "public_web" {
  name = "${var.name}-public-web"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "host" {
  name        = var.name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  labels      = var.labels
  user_data   = var.user_data
  firewall_ids = [
    hcloud_firewall.public_web.id
  ]

  public_net {
    ipv4 = hcloud_primary_ip.ipv4.id
    ipv6 = hcloud_primary_ip.ipv6.id
  }
}
