job "spark" {
  datacenters = ["dc1"]
  type        = "batch"

  group "single_node" {
    count = 1

    service {
      name = "spark"
    }

    ephemeral_disk {
      size = 300
    }

    task "spark" {
      driver = "docker"
      config {
        image = "ignitz/spark_single_node:3.1.1"
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
      }
    }
  }
}
