job "$service_name" {
  datacenters = [
    "factory-us-east-1",
    "dc1" # local development
  ]

  # Only schedule this job onto a worker node.
  type = "service"
  constraint {
    attribute = "$${node.class}"
    value     = "worker"
  }

  group "$service_name" {
    count = $count

    update {
      max_parallel = 1
    }

    task "$service_name" {
      driver = "docker"

      config {
        image = "$docker_image"

        port_map {
          http = 4180
        }

        # TODO: would like to have request-log-format here but
        # can't figure out how to get that into JSON w/ their
        # golang templating as it has no escaping
        args = [
          "--provider=google",
          "--email-domain=density.io",
          "--redirect-url=https://$service_name.density.build/oauth2/callback",
          "--upstream=$upstream",
          "--http-address=0.0.0.0:4180",
          "--request-logging=false",
          "--pass-access-token=false",
          "--pass-basic-auth=false",
          "--pass-host-header=false",
        ]

        logging {
          type = "json-file"
          config {
            max-size = "100m"
            max-file = 3
          }
        }

        labels {
          gelf_service_name="$service_name"
        }

      }

      resources {
        cpu = 512   # CPU share
        memory = 512 # MB
        network { port "http" {} }
      }

      # gives us 2s to refresh Nginx config after the instance
      # has been deregistered from Consul before we shut down.
      shutdown_delay = "12s"

      service {
        name = "$service_name"
        port = "http"
        tags = ["public"]
        check {
          type     = "http"
          port     = "http"
          path     = "/ping"
          interval = "10s"
          timeout  = "9s"
        }
      }

      template {
        data = <<EOH
        OAUTH2_PROXY_CLIENT_ID="{{ key "$service_name/oauth2_proxy_client_id" }}"
        OAUTH2_PROXY_CLIENT_SECRET="{{ key "$service_name/oauth2_proxy_client_secret" }}"
        OAUTH2_PROXY_COOKIE_DOMAIN="{{ key "$service_name/oauth2_proxy_cookie_domain" }}"
        OAUTH2_PROXY_COOKIE_SECRET="{{ key "service_name/oauth2_proxy_cookie_secret" }}"
        OAUTH2_PROXY_EMAIL_DOMAIN="density.io"
        EOH
        destination = "secrets/.env"
        env = true
        splay = "5s"
      }
    }
  }
}
