project = "example-python"

app "example-python" {
  labels = {
    "service" = "example-python",
    "env"     = "dev"
  }

  build {
    use "docker" {}
    registry {
      use "docker" {
        image = "ignitz/example-python"
        tag   = "latest"
      }
    }
  }

  deploy {
    use "nomad" {
      // these options both default to the values shown, but are left here to
      // show they are configurable
      datacenter = "dc1"
      namespace  = "default"
      service_port = 8080
      replicas = 1
    }
  }
}
