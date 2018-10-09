job "partkeepr" {
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

  group "partkeepr" {
    count = $count

    update {
      max_parallel = 1
    }

    task "partkeepr" {
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
          gelf_service_name="partkeepr"
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
    }
  }
}
