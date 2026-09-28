SHELL := /bin/bash
PACKER ?= packer

.PHONY: validate
validate:
	terraform fmt -check -recursive terraform experiments
	terraform -chdir=terraform init -backend=false -input=false -lockfile=readonly
	terraform -chdir=terraform validate
	terraform -chdir=experiments/no-content-trigger/terraform init -backend=false -input=false -lockfile=readonly
	terraform -chdir=experiments/no-content-trigger/terraform validate
	$(PACKER) fmt -check packer/site.pkr.hcl
	$(PACKER) init packer/site.pkr.hcl
	$(PACKER) validate packer/site.pkr.hcl
	python3 -m py_compile scripts/verify-runtime.py
