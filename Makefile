APP_NAME=apilm
MODEL_NAME=TinyLlama/TinyLlama-1.1B-Chat-v1.0
MODEL_DIR=./models

.PHONY: build run stop logs clean restart model prompt

build:
	docker compose build

run:
	docker compose up -d

stop:
	docker compose down

logs:
	docker compose logs -f

clean:
	docker compose down -v --remove-orphans
	-docker rmi $$(docker images -q $(APP_NAME)) || true

restart: stop run

model:
	@echo ">>> Installing huggingface_hub CLI if not installed"
	python3 -m pip install -U "huggingface_hub[cli]" || python -m pip install -U "huggingface_hub[cli]"
	@echo ">>> Downloading model $(MODEL_NAME) into $(MODEL_DIR)"
	huggingface-cli download $(MODEL_NAME) --local-dir $(MODEL_DIR)

prompt:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make prompt \"your text here\""; \
	else \
		TEXT="$(filter-out $@,$(MAKECMDGOALS))"; \
		curl -s -X POST http://localhost:8080/generate \
		  -H "Content-Type: application/json" \
		  -d "$$(printf '{"prompt":"%s"}' "$$TEXT")" | jq; \
	fi

%:
	@: