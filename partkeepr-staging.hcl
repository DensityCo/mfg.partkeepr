job "partkeepr-staging" {

  datacenters = [
    "${config.nomad.region}"
  ]

  # Only schedule this job onto a worker node.
  type = "service"

  constraint {
    attribute = "$${node.class}"
    value     = "worker"
  }

  group "partkeepr-staging" {
    count = "${app.service.count}"

    update {
      max_parallel = 1
    }

    task "partkeepr" {
      driver = "docker"

      config {
        image = "${docker_image}"

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
          gelf_service_name="partkeepr-staging"
        }

      }

      resources {
        cpu    = "${app.service.cpu}"
        memory = "${app.service.memory}"
        network { port "http" {} }
      }

      # gives us 2s to refresh Nginx config after the instance
      # has been deregistered from Consul before we shut down.
      shutdown_delay = "12s"

      service {
        name = "partkeepr-staging"
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
        PARTKEEPR_DATABASE_HOST="{{ key "partkeepr-staging/partkeepr_database_host" }}"
        PARTKEEPR_DATABASE_NAME="{{ key "partkeepr-staging/partkeepr_database_name" }}"
        PARTKEEPR_DATABASE_PORT="{{ key "partkeepr-staging/partkeepr_database_port" }}"
        PARTKEEPR_DATABASE_USER="{{ key "partkeepr-staging/partkeepr_database_user" }}"
        PARTKEEPR_DATABASE_PASS="{{ key "partkeepr-staging/partkeepr_database_pass" }}"
        PARTKEEPR_OKTOPART_APIKEY="{{ key "partkeepr-staging/partkeepr_oktopart_apikey" }}"
        PARTKEEPR_SECRET="{{ key "partkeepr-staging/partkeepr_secret" }}"
        PARTKEEPR_USERNAME="{{ key "partkeepr-staging/partkeepr_username" }}"
        PARTKEEPR_PASSWORD="{{ key "partkeepr-staging/partkeepr_password" }}"
        EOH
        destination = "secrets/.env"
        env = true
        splay = "5s"
      }
    }
  }
}
