"""
Cookbook AI Backend - Cấu hình
"""
import os
from dotenv import load_dotenv

load_dotenv()

# Flask Configuration
FLASK_ENV = os.getenv('FLASK_ENV', 'development')
FLASK_DEBUG = os.getenv('FLASK_DEBUG', 'True').lower() == 'true'

# OpenAI Configuration
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
OPENAI_MODEL = os.getenv('OPENAI_MODEL', 'gpt-3.5-turbo')

# Server Configuration
SERVER_HOST = '0.0.0.0'
SERVER_PORT = 5000
SERVER_DEBUG = FLASK_DEBUG

# API Configuration
API_TIMEOUT = 30  # seconds
API_MAX_RETRIES = 3
API_RETRY_DELAY = 1  # seconds

# AI Configuration
AI_TEMPERATURE = 0.7  # Độ sáng tạo (0-1)
AI_MAX_TOKENS = 2000

# Validation
if not OPENAI_API_KEY:
    raise ValueError(
        "⚠️  OPENAI_API_KEY không được thiết lập!\n"
        "Vui lòng tạo file .env trong thư mục python_backend:\n"
        "  1. cp .env.example .env\n"
        "  2. Thêm OPENAI_API_KEY vào file .env\n"
        "  3. Chạy lại server"
    )

print("✓ Cấu hình AI Backend được tải thành công")
