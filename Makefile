SHELL := /bin/sh

.PHONY: terraform/fmt terraform/validate bundle

terraform/fmt:
	terraform -chdir=infra/envs/prod fmt -recursive
	terraform -chdir=infra/envs/test fmt -recursive
	terraform -chdir=infra/envs/ops fmt -recursive

terraform/validate:
	terraform -chdir=infra/envs/prod init -backend=false
	terraform -chdir=infra/envs/prod validate
	terraform -chdir=infra/envs/test init -backend=false
	terraform -chdir=infra/envs/test validate
	terraform -chdir=infra/envs/ops init -backend=false
	terraform -chdir=infra/envs/ops validate

bundle:
	./scripts/package_bootstrap_bundle.sh "$(VERSION)"
