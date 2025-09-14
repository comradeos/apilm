APP_NAME=apilm
MODEL_NAME?=sshleifer/tiny-gpt2
MODEL_DIR=./models

.PHONY: build run stop logs clean restart model

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
	python -m pip show huggingface_hub >/dev/null 2>&1 || python -m pip install -U "huggingface_hub[cli]"
	python -m huggingface_hub download $(MODEL_NAME) --local-dir $(MODEL_DIR)