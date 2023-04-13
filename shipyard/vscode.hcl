variable "vscode_password" {
  default = "testing123"
}

variable "docs_location" {
  default = "http://localhost:3000/"
}

template "vscode" {
  source = <<-EOF
  {
    "tabs": [
      {"uri": "${var.docs_location}", "title": "Docs"}
    ],
    "terminals": [
      {"name": "Terraform", "viewColumn": 1}
    ]
  }
  EOF

  destination = "${data("vscode")}/shipyard.json"
}

container "vscode" {
  depends_on = ["template.vscode"]

  network {
    name       = "network.dc1"
    ip_address = "10.5.0.200"
  }

  image {
    name = "shipyardrun/docker-devs-vscode:v0.0.2"
  }

  env {
    key   = "AUTH_KEY"
    value = var.vscode_password
  }

  port {
    local  = 8000
    remote = 8000
    host   = 8000
  }

  volume {
    source      = "./terraform"
    destination = "/root/code"
  }

  volume {
    source      = "./lib"
    destination = "/var/lib/jumppad"
  }

  volume {
    destination = "/root/code/.vscode"
    source      = data("vscode")
  }
}