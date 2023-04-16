docs "docs" {
  path  = "./docs"
  port  = 3000
  open_in_browser = false

  image {
    name = "shipyardrun/docs:v0.6.3"
  }

  index_title = "Terraform"

  network {
    name = "network.dc1"
    ip_address = "10.5.0.201"
  }
}