FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    torch==2.3.0 \
    transformers==4.44.0 \
    accelerate==0.32.1 \
    flask==3.0.3 \
    gunicorn==23.0.0 \
    bitsandbytes==0.47.0

WORKDIR /app

COPY app/app.py /app/app.py

EXPOSE 8080

CMD ["gunicorn", "-b", "0.0.0.0:8080", "-w", "1", "--timeout", "300", "app:app"]