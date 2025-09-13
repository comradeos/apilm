APP_NAME=apilm
MODEL_NAME=sshleifer/tiny-gpt2
MODEL_DIR=./models

.PHONY: build run stop logs clean restart download-model

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
	docker rmi $$(docker images -q $(APP_NAME)) || true

restart: stop run

download-model:
	python3 -m pip show huggingface_hub >/dev/null 2>&1 || python3 -m pip install -U "huggingface_hub[cli]"
	huggingface-cli download $(MODEL_NAME) --local-dir $(MODEL_DIR)/TinyLlama