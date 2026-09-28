# Building Docker images with Terraform and Packer

A small, executed lab for understanding image creation, explicit rebuild
triggers, and the handoff between a built image and a running container.

Read the [technical article](docs/article.md) for the explanations and diagrams.

It contains two implementations of the same static page:

- Terraform builds a Dockerfile and manages the consuming container.
- Packer provisions a temporary container, commits an image, and tags it.

The [recorded evidence](evidence/README.md) includes real browser screenshots,
sanitized runtime assertions, source hashes, and the initial Packer failure.
No Azure deployment or registry publication was performed.

## Tested environment

| Tool | Version |
|---|---|
| Terraform | 1.14.7 |
| Terraform Docker provider | 4.6.0 |
| Packer | 1.14.3 |
| Packer Docker plugin | 1.1.4 |
| Docker client / server | 29.4.3 / 29.6.2 |
| BuildKit | 0.31.2 |

The run used macOS on Apple silicon with Docker Desktop's `desktop-linux`
context. The examples require Linux containers, Python 3 for the verifier,
and the listed CLIs. Other host combinations need their own execution checks.
The readable `python:3.13-alpine` base tag is mutable. Pin an approved digest
and control other inputs before claiming reproducible builds.

## Before running

Use an authorized disposable local Docker daemon. Verify its current context
and check that `mvp-image-lab-*` names and ports 18080–18082 are unused. The
examples bind only to loopback, use a non-root runtime user, and grant no cloud
permissions. Docker access itself remains powerful; these examples are not a
sandbox for untrusted build recipes.

Clone the companion repository first:

```bash
git clone https://github.com/SalehElnagar/terraform-packer-docker-images.git
cd terraform-packer-docker-images
```

Run all commands below from the repository root. These commands build images
and create containers; review plans before applying them. Do not apply or
clean up resources you do not own.

```bash
export DOCKER_CONTEXT=desktop-linux
export TF_VAR_docker_host="$(docker context inspect desktop-linux --format '{{.Endpoints.docker.Host}}')"
make validate
```

The Terraform input rejects remote URIs. Confirm the socket belongs to the
intended daemon; a Unix URI alone does not prove isolation.

## Terraform: baseline, edit, rebuild

```bash
terraform -chdir=terraform plan -out=baseline.tfplan
# Review the exact plan before continuing.
terraform -chdir=terraform apply baseline.tfplan
python3 scripts/verify-runtime.py --container mvp-image-lab-terraform \
  --port 18080 --source app/index.html
```

Open `http://127.0.0.1:18080/`. The baseline serves version one.

Change the heading in `app/index.html` to version two. Before rebuilding,
refresh the browser: the container still serves version one. There is no bind
mount. Then:

```bash
terraform -chdir=terraform plan -out=update.tfplan
# Review the image and container replacements.
terraform -chdir=terraform apply update.tfplan
python3 scripts/verify-runtime.py --container mvp-image-lab-terraform \
  --port 18080 --source app/index.html
```

The content hash changes, the image is rebuilt, and the response becomes
version two. Keep the source files unchanged between planning and applying;
the plan does not package the build context.

## Negative case: omit the content trigger

`experiments/no-content-trigger` has its own page, Terraform state directory,
resource names, and loopback port. Only the HTML content hash is omitted from
its trigger map; the Dockerfile and ignore-rule hashes remain.

```bash
terraform -chdir=experiments/no-content-trigger/terraform plan -out=baseline.tfplan
# Review the isolated lab additions.
terraform -chdir=experiments/no-content-trigger/terraform apply baseline.tfplan
```

Open `http://127.0.0.1:18082/` and confirm version one. Edit only
`experiments/no-content-trigger/app/index.html` to version two, then run:

```bash
terraform -chdir=experiments/no-content-trigger/terraform plan
```

The recorded experiment produced no changes, while HTTP still returned version
one. Do not delete the trigger from an already-created positive baseline:
changing the map would itself be a trigger change.

## Packer: build and check the runtime

Restore `app/index.html` to the baseline if you want to compare the two original
version-one images. Packer includes whichever file is present at build time.

```bash
packer init packer/site.pkr.hcl
packer validate packer/site.pkr.hcl
packer build packer/site.pkr.hcl

docker run -d --name mvp-image-lab-packer \
  --read-only --cap-drop=ALL --security-opt no-new-privileges:true \
  -p 127.0.0.1:18081:8080 mvp-image-lab-packer:demo
python3 scripts/verify-runtime.py --container mvp-image-lab-packer \
  --port 18081 --source app/index.html
```

Open `http://127.0.0.1:18081/`. The verifier checks the complete HTTP response,
process, non-root user, read-only root, capabilities, no-new-privileges, absence
of mounts, and loopback-only port mapping. A successful build alone is weaker
evidence.

The initial Packer recipe used `ENTRYPOINT []`. In this environment, the built
image retained `/bin/sh` and failed at runtime. The corrected recipe sets
`ENTRYPOINT ["python"]` and places the remaining arguments in `CMD`. The failed
attempt and passing rerun are both recorded.

## Cleanup

Review each destroy plan before applying it to the matching lab state:

```bash
terraform -chdir=terraform plan -destroy -out=cleanup.tfplan
terraform -chdir=terraform apply cleanup.tfplan
terraform -chdir=experiments/no-content-trigger/terraform plan -destroy -out=cleanup.tfplan
terraform -chdir=experiments/no-content-trigger/terraform apply cleanup.tfplan
```

Separately stop and remove the named Packer runtime container and remove its
exact lab image after checking references. Do not run a broad Docker prune.
Verify the lab resources are gone before removing local state. State, saved
plans, raw logs, downloaded tools, and credentials are excluded from Git.

Python's development HTTP server is only a teaching aid. These results do not
establish production security, availability, or safe database rollback.
