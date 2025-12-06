from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import logging
from dotenv import load_dotenv
from ai_service import AIService
from recipe_cloner import RecipeCloner

# Cấu hình logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

app = Flask(__name__)
CORS(app)

# Khởi tạo AI Service với model tự build
ai_service = AIService(
    model=os.getenv('AI_MODEL', 'gemma3n:e2b'),
    host=os.getenv('AI_HOST', 
                #    'http://192.168.1.222:8070/v1/chat/completions'
                   'http://localhost:11434/api/chat'
                   )
)

# Khởi tạo RecipeCloner
recipe_cloner = RecipeCloner()

logger.info("="*50)
logger.info("🚀 Cookbook AI Backend Starting...")
logger.info(f"📍 Host: 0.0.0.0:5000")
logger.info(f"🤖 AI Model: {os.getenv('AI_MODEL', 'gemma3n:e2b')}")
logger.info(f"🔗 AI Host: {os.getenv('AI_HOST', 'http://localhost:11434/api/chat')}")
logger.info("="*50)

# ===== API Endpoints =====

@app.route('/api/health', methods=['GET'])
def health():
    """Kiểm tra server có hoạt động"""
    logger.info("📊 Health check request received")
    return jsonify({"status": "ok", "message": "AI Backend đang chạy"}), 200


@app.route('/api/suggest-recipe', methods=['POST'])
def suggest_recipe():
    """Gợi ý công thức dựa trên nguyên liệu hoặc tên
    Request JSON:
    {
        "ingredients": ["cà chua", "dưa chuột"],
        "cuisine": "Việt Nam",
        "difficulty": "dễ"
    }
    """
    try:
        data = request.get_json()
        ingredients = data.get('ingredients', [])
        cuisine = data.get('cuisine', '')
        difficulty = data.get('difficulty', '')
        
        prompt = f"""Gợi ý một công thức nấu ăn dựa trên:
- Nguyên liệu: {', '.join(ingredients)}
- Loại ẩm thực: {cuisine}
- Mức độ khó: {difficulty}

Vui lòng trả lời dưới dạng JSON với các field:
{{
    "title": "Tên công thức",
    "description": "Mô tả ngắn",
    "ingredients": ["Nguyên liệu 1", "Nguyên liệu 2"],
    "steps": ["Bước 1", "Bước 2"],
    "estimatedTime": "30 phút",
    "servings": 4
}}
"""
        
        result = ai_service.generate_recipe(prompt)
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/meal-plan', methods=['POST'])
def generate_meal_plan():
    """Tạo kế hoạch ăn uống hàng tuần
    Request JSON:
    {
        "days": 7,
        "dietary": "vegetarian",
        "preferences": ["không cay", "có cá"]
    }
    """
    try:
        data = request.get_json()
        days = data.get('days', 7)
        dietary = data.get('dietary', '')
        preferences = data.get('preferences', [])
        
        prompt = f"""Tạo kế hoạch ăn uống {days} ngày với:
- Chế độ ăn: {dietary}
- Sở thích: {', '.join(preferences)}

Trả lời dưới dạng JSON:
{{
    "plan": [
        {{
            "day": "Thứ 2",
            "breakfast": "Tên công thức",
            "lunch": "Tên công thức",
            "dinner": "Tên công thức"
        }}
    ]
}}
"""
        result = ai_service.generate_meal_plan(prompt)
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/analyze-recipe', methods=['POST'])
def analyze_recipe():
    """Phân tích thông tin dinh dưỡng của công thức
    Request JSON:
    {
        "title": "Tên công thức",
        "ingredients": ["Nguyên liệu 1: 100g", "Nguyên liệu 2: 50g"]
    }
    """
    try:
        data = request.get_json()
        title = data.get('title', '')
        ingredients = data.get('ingredients', [])
        
        prompt = f"""Phân tích thông tin dinh dưỡng của công thức: {title}
Nguyên liệu:
{chr(10).join(['- ' + ing for ing in ingredients])}

Trả lời dưới dạng JSON:
{{
    "calories": 500,
    "protein": 25,
    "carbs": 60,
    "fat": 15,
    "nutrition": "Phân tích chi tiết",
    "healthBenefits": ["Lợi ích 1", "Lợi ích 2"]
}}
"""
        result = ai_service.analyze_nutrition(prompt)
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/cooking-tips', methods=['POST'])
def get_cooking_tips():
    """Lấy mẹo nấu nướng
    Request JSON:
    {
        "dish": "Tên món ăn",
        "problem": "Vấn đề cần giải quyết"
    }
    """
    try:
        data = request.get_json()
        dish = data.get('dish', '')
        problem = data.get('problem', '')
        
        prompt = f"""Cung cấp mẹo nấu nướng cho: {dish}
Vấn đề: {problem}

Trả lời dưới dạng JSON:
{{
    "tips": ["Mẹo 1", "Mẹo 2", "Mẹo 3"],
    "explanation": "Giải thích chi tiết"
}}
"""
        result = ai_service.get_tips(prompt)
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ===== Recipe Clone API =====

@app.route('/api/clone/statistics', methods=['GET'])
def get_clone_statistics():
    """Lấy thống kê công thức trong database"""
    try:
        stats = recipe_cloner.get_statistics()
        return jsonify(stats), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/clone/from-json', methods=['POST'])
def clone_from_json():
    """Clone công thức từ JSON file
    Request:
    {
        "json_file": "/path/to/file.json"
    }
    """
    try:
        data = request.get_json()
        json_file = data.get('json_file', '')
        
        if not json_file:
            return jsonify({"error": "json_file is required"}), 400
        
        count = recipe_cloner.clone_from_json(json_file)
        stats = recipe_cloner.get_statistics()
        
        return jsonify({
            "message": f"Imported {count} recipes",
            "count": count,
            "statistics": stats
        }), 200
    except Exception as e:
        logger.error(f"Error cloning from JSON: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/clone/from-api', methods=['POST'])
def clone_from_api():
    """Clone công thức từ API
    Request:
    {
        "api_url": "https://api.example.com/recipes"
    }
    """
    try:
        data = request.get_json()
        api_url = data.get('api_url', '')
        
        if not api_url:
            return jsonify({"error": "api_url is required"}), 400
        
        count = recipe_cloner.clone_from_api(api_url)
        stats = recipe_cloner.get_statistics()
        
        return jsonify({
            "message": f"Imported {count} recipes from API",
            "count": count,
            "statistics": stats
        }), 200
    except Exception as e:
        logger.error(f"Error cloning from API: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/clone/from-preset', methods=['POST'])
def clone_from_preset():
    """Clone công thức từ preset_recipes.json
    Request: {} (body trống)
    """
    try:
        count = recipe_cloner.clone_from_preset()
        stats = recipe_cloner.get_statistics()
        
        return jsonify({
            "message": f"Imported {count} recipes from preset",
            "count": count,
            "statistics": stats
        }), 200
    except Exception as e:
        logger.error(f"Error cloning from preset: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/clone/add-manual', methods=['POST'])
def add_manual_recipe():
    """Thêm công thức thủ công
    Request:
    {
        "title": "Tên công thức",
        "description": "Mô tả",
        "ingredients": ["Nguyên liệu 1", "Nguyên liệu 2"],
        "steps": ["Bước 1", "Bước 2"],
        "durationInMinutes": 30,
        "type": "Loại",
        "imageUrl": "URL hình ảnh"
    }
    """
    try:
        data = request.get_json()
        
        required_fields = ['title', 'description', 'ingredients', 'steps']
        if not all(field in data for field in required_fields):
            return jsonify({
                "error": f"Missing required fields: {', '.join(required_fields)}"
            }), 400
        
        success = recipe_cloner.add_manual_recipe(
            title=data['title'],
            description=data['description'],
            ingredients=data['ingredients'],
            steps=data['steps'],
            duration=data.get('durationInMinutes', 30),
            recipe_type=data.get('type', 'Khác'),
            image_url=data.get('imageUrl', '')
        )
        
        if success:
            stats = recipe_cloner.get_statistics()
            return jsonify({
                "message": "Recipe added successfully",
                "statistics": stats
            }), 200
        else:
            return jsonify({"error": "Failed to add recipe"}), 400
    
    except Exception as e:
        logger.error(f"Error adding manual recipe: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/clone/recipes', methods=['GET'])
def get_all_recipes():
    """Lấy danh sách tất cả công thức"""
    try:
        recipes = recipe_cloner.list_all_recipes()
        return jsonify({
            "total": len(recipes),
            "recipes": recipes
        }), 200
    except Exception as e:
        logger.error(f"Error fetching recipes: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/clone/clear', methods=['POST'])
def clear_all_recipes():
    """Xóa tất cả công thức (CẢNH BÁO!)
    Request: {} (body trống)
    """
    try:
        # Thêm xác nhận bằng cách require 1 header đặc biệt
        if request.headers.get('X-Confirm-Delete') != 'true':
            return jsonify({
                "error": "Confirmation required. Send X-Confirm-Delete: true header"
            }), 400
        
        success = recipe_cloner.clear_all()
        
        if success:
            return jsonify({
                "message": "All recipes deleted successfully",
                "statistics": recipe_cloner.get_statistics()
            }), 200
        else:
            return jsonify({"error": "Failed to clear recipes"}), 500
    
    except Exception as e:
        logger.error(f"Error clearing recipes: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    # Development: địa chỉ 0.0.0.0 để chạy trên mạng cục bộ
    logger.info("✅ Backend đã sẵn sàng!")
    logger.info("🌐 Truy cập: http://localhost:5000/api/health")
    logger.info("📱 App sẽ kết nối đến: http://localhost:5000/api")
    logger.info("")
    app.run(host='0.0.0.0', port=5000, debug=True)
