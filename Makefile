TF ?= terraform
PY ?= python3
EXAMPLE_DIRS := examples/ec2 examples/pod

.PHONY: all fmt fmt-fix validate examples test lint security docs docs-check clean

all: fmt validate examples test lint security docs-check

fmt:
	$(TF) fmt -recursive -check

fmt-fix:
	$(TF) fmt -recursive

validate:
	$(TF) init -backend=false -input=false
	$(TF) validate

examples:
	@for d in $(EXAMPLE_DIRS); do \
		echo "== validating $$d =="; \
		$(TF) -chdir=$$d init -backend=false -input=false; \
		$(TF) -chdir=$$d validate; \
	done

test:
	$(TF) test

lint:
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init && tflint --recursive; \
	else \
		echo "tflint not installed; skipping"; \
	fi

security:
	@if command -v checkov >/dev/null 2>&1; then \
		checkov -d . --quiet --compact; \
	else \
		echo "checkov not installed; skipping"; \
	fi

docs:
	$(PY) scripts/generate_template_docs.py

docs-check:
	$(PY) scripts/generate_template_docs.py --check

clean:
	rm -rf .terraform examples/*/.terraform
