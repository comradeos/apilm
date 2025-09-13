import os
import torch
from flask import Flask, request, jsonify
from transformers import AutoModelForCausalLM, AutoTokenizer


DEFAULT_MODEL = "sshleifer/tiny-gpt2"
MODEL_NAME = os.getenv("MODEL_NAME", DEFAULT_MODEL)
MODEL_PATH = os.getenv("MODEL_PATH", "/models")


def get_device() -> str:
    """Определяем доступное устройство."""
    if torch.cuda.is_available():
        return "cuda"
    elif torch.backends.mps.is_available():
        return "mps"
    return "cpu"


DEVICE = get_device()
print(f"Loading model {MODEL_NAME} on {DEVICE}...")


def load_tokenizer(model_name: str, model_path: str):
    """Загружаем токенизатор."""
    return AutoTokenizer.from_pretrained(model_name, cache_dir=model_path)


def load_model(model_name: str, model_path: str, device: str):
    """Загружаем модель. Пробуем 8-битный режим, если не получится — full precision."""
    try:
        from transformers import BitsAndBytesConfig

        quant_config = BitsAndBytesConfig(load_in_8bit=True)

        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            cache_dir=model_path,
            quantization_config=quant_config,
            device_map="auto",
        )
        print("Model loaded in 8-bit mode")
    except Exception as e:
        print(f"8-bit mode not available: {e}")
        model = AutoModelForCausalLM.from_pretrained(
            model_name, cache_dir=model_path
        ).to(device)
        print("Model loaded in full precision")

    return model


tokenizer = load_tokenizer(MODEL_NAME, MODEL_PATH)
model = load_model(MODEL_NAME, MODEL_PATH, DEVICE)


def generate_text(prompt: str, max_tokens: int = 50) -> str:
    """Генерируем текст по промпту."""
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    inputs = tokenizer(prompt, return_tensors="pt").to(DEVICE)
    outputs = model.generate(
        **inputs, max_new_tokens=max_tokens, pad_token_id=tokenizer.pad_token_id
    )
    return tokenizer.decode(
        outputs[0], skip_special_tokens=True, clean_up_tokenization_spaces=False
    )


app = Flask(__name__)


@app.route("/generate", methods=["POST"])
def generate_endpoint():
    """Эндпоинт для генерации текста."""
    try:
        data = request.get_json(force=True)
        prompt = data.get("prompt", "")

        if not prompt.strip():
            return jsonify({"error": "Empty prompt"}), 400

        text = generate_text(prompt)
        return jsonify({"response": text})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/health", methods=["GET"])
def health():
    """Эндпоинт для проверки состояния сервиса."""
    status = {"status": "ok", "model": MODEL_NAME, "device": DEVICE}
    return jsonify(status)
