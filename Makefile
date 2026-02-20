.PHONY: help inventory lint test

help:
	@echo "yai-infra"
	@echo "  make inventory  - generate extraction pack (.YAI/*) for all repos"
	@echo "  make lint       - run linters"
	@echo "  make test       - run tests"

inventory:
	@python3 -m yai_infra_tools.project.inventory --root ../ --out ./.YAI

lint:
	@echo "TODO: add ruff/black/mypy"

test:
	@echo "TODO: add pytest"
