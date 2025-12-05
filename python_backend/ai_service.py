import json
import requests
from typing import Dict, Any, List


class AIService:
    """Service xử lý các yêu cầu AI - Sử dụng custom AI model"""
    
    def __init__(self, model: str = "gemma3n:e4b", host: str = "http://192.168.1.222:8070/v1/chat/completions"):
        """
        Khởi tạo dịch vụ AI
        
        Args:
            model: Tên model AI (mặc định: gemma3n:e4b)
            host: URL của AI backend server (mặc định: http://192.168.1.222:8070/v1/chat/completions)
        """
        self.model = model
        self.host = host
        self.max_token = 20000
        self.temperature = 0.6
        self.top_p = 0.8
        self.top_k = 20
        self.min_p = 0.0
    
    def _call_chat_api(self, messages: List[Dict[str, str]]) -> Dict[str, Any]:
        """
        Gọi custom AI API
        
        Args:
            messages: Danh sách message định dạng OpenAI
            
        Returns:
            Response từ API
        """
        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {
                "num_ctx": self.max_token,
                "temperature": self.temperature,
                "top_p": self.top_p,
                "top_k": self.top_k,
                "min_p": self.min_p,
            },
            "tools": None
        }
        
        try:
            response = requests.post(self.host, json=payload, timeout=60)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": f"Lỗi gọi AI API: {str(e)}"}
    
    def generate_recipe(self, prompt: str) -> Dict[str, Any]:
        """
        Tạo công thức từ prompt
        
        Returns:
            Dict chứa thông tin công thức
        """
        try:
            messages = [
                {
                    "role": "system",
                    "content": "Bạn là một đầu bếp chuyên nghiệp. Luôn trả lời dưới dạng JSON hợp lệ."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ]
            
            response = self._call_chat_api(messages)
            
            if "error" in response:
                return response
            
            # Trích xuất content từ response
            content = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            if not content:
                return {"error": "Không nhận được response từ AI"}
            
            result = self._parse_json_response(content)
            return result
        except Exception as e:
            return {"error": f"Lỗi tạo công thức: {str(e)}"}
    
    def generate_meal_plan(self, prompt: str) -> Dict[str, Any]:
        """
        Tạo kế hoạch ăn uống
        
        Returns:
            Dict chứa kế hoạch ăn uống
        """
        try:
            messages = [
                {
                    "role": "system",
                    "content": "Bạn là một chuyên gia dinh dưỡng. Luôn trả lời dưới dạng JSON hợp lệ."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ]
            
            response = self._call_chat_api(messages)
            
            if "error" in response:
                return response
            
            content = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            if not content:
                return {"error": "Không nhận được response từ AI"}
            
            result = self._parse_json_response(content)
            return result
        except Exception as e:
            return {"error": f"Lỗi tạo kế hoạch: {str(e)}"}
    
    def analyze_nutrition(self, prompt: str) -> Dict[str, Any]:
        """
        Phân tích thông tin dinh dưỡng
        
        Returns:
            Dict chứa thông tin dinh dưỡng
        """
        try:
            messages = [
                {
                    "role": "system",
                    "content": "Bạn là một chuyên gia dinh dưỡng. Luôn trả lời dưới dạng JSON hợp lệ."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ]
            
            response = self._call_chat_api(messages)
            
            if "error" in response:
                return response
            
            content = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            if not content:
                return {"error": "Không nhận được response từ AI"}
            
            result = self._parse_json_response(content)
            return result
        except Exception as e:
            return {"error": f"Lỗi phân tích dinh dưỡng: {str(e)}"}
    
    def get_tips(self, prompt: str) -> Dict[str, Any]:
        """
        Lấy mẹo nấu nướng
        
        Returns:
            Dict chứa các mẹo
        """
        try:
            messages = [
                {
                    "role": "system",
                    "content": "Bạn là một đầu bếp giàu kinh nghiệm. Cung cấp mẹo thực tiễn hữu ích. Luôn trả lời dưới dạng JSON hợp lệ."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ]
            
            response = self._call_chat_api(messages)
            
            if "error" in response:
                return response
            
            content = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            if not content:
                return {"error": "Không nhận được response từ AI"}
            
            result = self._parse_json_response(content)
            return result
        except Exception as e:
            return {"error": f"Lỗi lấy mẹo: {str(e)}"}
    
    @staticmethod
    def _parse_json_response(content: str) -> Dict[str, Any]:
        """
        Phân tích JSON response từ AI
        
        Args:
            content: Nội dung response từ AI
            
        Returns:
            Dict được phân tích hoặc dict chứa error
        """
        try:
            # Loại bỏ markdown code blocks nếu có
            if content.startswith("```"):
                content = content.split("```")[1]
                if content.startswith("json"):
                    content = content[4:]
            
            result = json.loads(content)
            return result
        except json.JSONDecodeError as e:
            return {"error": f"Lỗi phân tích JSON: {str(e)}", "raw_content": content}
