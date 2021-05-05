job "database" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    progress_deadline = "10m"
    auto_revert       = false
    canary            = 0
  }
  migrate {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }
  group "postgres" {
    count = 1
    network {
      port "db" {
        static = 5432
      }
    }

    service {
      name = "postgres"
      tags = ["global", "database"]
      port = "db"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }
    ephemeral_disk {
      size = 300
    }

    task "postgres" {
      driver = "docker"
      config {
        image = "postgres:13"
        ports = ["db"]
      }

      env {
        POSTGRES_PASSWORD = "password"
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
      }
    }
  }

  group "mysql" {
    count = 1

    network {
      port "db" {
        static = 3306
      }
    }

    service {
      name = "mysql"
      tags = ["global", "database"]
      port = "db"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "mysql" {
      driver = "docker"

      env = {
        "MYSQL_ROOT_PASSWORD" = "password"
      }

      config {
        image = "hashicorp/mysql-portworx-demo:latest"
        ports = ["db"]
      }

      resources {
        cpu    = 500
        memory = 1024
      }

    }
  }
}
