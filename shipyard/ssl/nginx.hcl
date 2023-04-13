variable "nginx_docs_domain" {
  default = "docs.local.env.jumppad.dev"
}

variable "nginx_code_domain" {
  default = "code.local.env.jumppad.dev"
}

certificate_ca "nginx_ca" {
  output = data("certs")
}

certificate_leaf "nginx" {
  depends_on = ["certificate_ca.nginx_ca"]

  ca_key = "${data("certs")}/nginx_ca.key"
  ca_cert = "${data("certs")}/nginx_ca.cert"

  ip_addresses = ["127.0.0.1"]

  dns_names = [
    "localhost",
    "*.local.env.jumppad.dev"
  ]

  output = data("certs")
}

template "nginx_config_ssl" {
  source = <<-EOF
    ssl_certificate /etc/nginx/ssl/nginx.cert;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    ssl_protocols TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
    ssl_session_timeout  10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off; # Requires nginx >= 1.5.9
    ssl_stapling on; # Requires nginx >= 1.3.7
    ssl_stapling_verify on; # Requires nginx => 1.3.7
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    # Disable strict transport security for now. You can uncomment the following
    # line if you understand the implications.
    add_header Strict-Transport-Security "max-age=0; includeSubDomains; preload";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    server {
      listen 80;
      listen [::]:80;

      server_name 192.168.2.111;

      return 302 https://$server_name$request_uri;
    }

    server {
      listen      443 ssl;
      listen      [::]:443 ssl;
      server_name ${var.nginx_docs_domain};

      location / {
        proxy_pass http://10.5.0.201;
        proxy_http_version 1.1;
      }
    }

    server {
      listen      443 ssl;
      listen      [::]:443 ssl;
      server_name ${var.nginx_code_domain};

      location / {
        proxy_pass http://10.5.0.200:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Accept-Encoding gzip;
      }
    }
  EOF

  destination = "${data("nginx")}/nginx.conf"
}

container "nginx" {
  depends_on = ["template.nginx_config_ssl"]

  network {
    name = "network.dc1"
  }

  image {
    name = "nginx:latest"
  }

  port {
    local  = 443
    remote = 443
    host   = 443
  }

  volume {
    source = "${data("nginx")}/nginx.conf"
    destination = "/etc/nginx/conf.d/default.conf"
  }

  volume {
    source = data("certs")
    destination = "/etc/nginx/ssl"
  }
}