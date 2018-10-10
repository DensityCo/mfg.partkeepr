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
          http = 80
        }

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
          path     = "/setup/"
          interval = "10s"
          timeout  = "9s"
        }
      }

      template {
        data = <<EOH
        PARTKEEPR_DATABASE_HOST="{{ key "$service_name/partkeepr_database_host" }}"
        PARTKEEPR_DATABASE_NAME="{{ key "$service_name/partkeepr_database_name" }}"
        PARTKEEPR_DATABASE_PORT="{{ key "$service_name/partkeepr_database_port" }}"
        PARTKEEPR_DATABASE_USER="{{ key "$service_name/partkeepr_database_user" }}"
        PARTKEEPR_DATABASE_PASS="{{ key "$service_name/partkeepr_database_pass" }}"
        PARTKEEPR_OKTOPART_APIKEY="{{ key "partkeepr-staging/partkeepr_oktopart_apikey" }}"
        EOH
        destination = "secrets/.env"
        env = true
        splay = "5s"
      }
    }
  }
}
