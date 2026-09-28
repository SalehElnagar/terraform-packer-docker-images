packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "= 1.1.4"
    }
  }
}

source "docker" "site" {
  image  = "python:3.13-alpine"
  commit = true

  changes = [
    "WORKDIR /site",
    "USER 10001:10001",
    "EXPOSE 8080",
    "ENTRYPOINT [\"python\"]",
    "CMD [\"-m\", \"http.server\", \"8080\", \"--bind\", \"0.0.0.0\", \"--directory\", \"/site\"]"
  ]
}

build {
  sources = ["source.docker.site"]

  provisioner "shell" {
    inline = ["mkdir -p /site && chmod 755 /site"]
  }

  provisioner "file" {
    source      = "${path.root}/../app/index.html"
    destination = "/site/index.html"
  }

  provisioner "shell" {
    inline = ["chmod 644 /site/index.html"]
  }

  post-processor "docker-tag" {
    repository = "mvp-image-lab-packer"
    tags       = ["demo"]
  }
}
