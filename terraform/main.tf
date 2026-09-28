terraform {
  required_version = "= 1.14.7"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "= 4.6.0"
    }
  }
}

variable "docker_host" {
  description = "Explicit local Unix socket for the disposable lab Docker daemon."
  type        = string

  validation {
    condition     = startswith(var.docker_host, "unix:///")
    error_message = "Use a local Unix socket; remote Docker targets are outside this lab."
  }
}

provider "docker" {
  host = var.docker_host
}

resource "docker_image" "app" {
  name = "mvp-image-lab-terraform:demo"

  build {
    context = "${path.module}/../app"
  }

  triggers = {
    dockerfile = filesha256("${path.module}/../app/Dockerfile")
    content    = filesha256("${path.module}/../app/index.html")
    ignore     = filesha256("${path.module}/../app/.dockerignore")
  }
}

resource "docker_container" "app" {
  name          = "mvp-image-lab-terraform"
  image         = docker_image.app.image_id
  read_only     = true
  security_opts = ["no-new-privileges:true"]

  capabilities {
    drop = ["ALL"]
  }

  ports {
    internal = 8080
    external = 18080
    ip       = "127.0.0.1"
  }
}
