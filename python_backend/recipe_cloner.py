"""
Tool để Clone công thức nấu ăn từ nhiều nguồn và thêm vào database
Hỗ trợ:
- Clone từ websites (web scraping)
- Clone từ JSON file
- Clone từ API
- Clone từ input manual
"""

import os
import sys
import json
import sqlite3
import requests
from datetime import datetime
from typing import List, Dict, Any, Optional
import logging

# Cấu hình logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class RecipeCloner:
    """Tool để clone và thêm công thức vào database"""
    
    def __init__(self, db_path: str = "recipes.db"):
        """
        Khởi tạo RecipeCloner
        
        Args:
            db_path: Đường dẫn đến database
        """
        self.db_path = db_path
        self._init_db()
        logger.info(f"✅ RecipeCloner initialized with database: {db_path}")
    
    def _init_db(self):
        """Tạo tables nếu chưa tồn tại"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Tạo bảng recipes
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS recipes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    title TEXT NOT NULL,
                    imageUrl TEXT,
                    description TEXT,
                    steps TEXT,
                    durationInMinutes INTEGER,
                    type TEXT,
                    source TEXT,
                    cloned_at TEXT
                )
            ''')
            
            # Tạo bảng ingredients
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS ingredients (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    recipeId INTEGER NOT NULL,
                    name TEXT NOT NULL,
                    isChecked INTEGER DEFAULT 0,
                    FOREIGN KEY(recipeId) REFERENCES recipes(id) ON DELETE CASCADE
                )
            ''')
            
            conn.commit()
            conn.close()
            logger.info("📊 Database tables verified/created successfully")
        except Exception as e:
            logger.error(f"❌ Error initializing database: {e}")
            raise
    
    def clone_from_json(self, json_file: str) -> int:
        """
        Clone công thức từ JSON file
        
        Format JSON:
        [
            {
                "title": "Tên công thức",
                "imageUrl": "URL hình ảnh",
                "description": "Mô tả",
                "durationInMinutes": 30,
                "type": "Loại",
                "ingredients": ["Nguyên liệu 1", "Nguyên liệu 2"],
                "steps": ["Bước 1", "Bước 2"]
            }
        ]
        
        Args:
            json_file: Đường dẫn file JSON
            
        Returns:
            Số công thức được thêm thành công
        """
        logger.info(f"📂 Reading recipes from JSON: {json_file}")
        
        if not os.path.exists(json_file):
            logger.error(f"❌ File not found: {json_file}")
            return 0
        
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                recipes = json.load(f)
            
            if not isinstance(recipes, list):
                recipes = [recipes]
            
            count = 0
            for recipe in recipes:
                if self._add_recipe(recipe, source="json_import"):
                    count += 1
            
            logger.info(f"✅ Successfully imported {count}/{len(recipes)} recipes")
            return count
            
        except json.JSONDecodeError as e:
            logger.error(f"❌ Invalid JSON format: {e}")
            return 0
        except Exception as e:
            logger.error(f"❌ Error reading JSON file: {e}")
            return 0
    
    def clone_from_api(self, api_url: str, headers: Optional[Dict] = None) -> int:
        """
        Clone công thức từ API
        
        Args:
            api_url: URL của API
            headers: Headers cho request (optional)
            
        Returns:
            Số công thức được thêm thành công
        """
        logger.info(f"🌐 Fetching recipes from API: {api_url}")
        
        try:
            response = requests.get(api_url, headers=headers or {}, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            # Xử lý nếu data là dict với key chứa list
            if isinstance(data, dict):
                recipes = data.get('recipes', data.get('data', [data]))
            else:
                recipes = data
            
            if not isinstance(recipes, list):
                recipes = [recipes]
            
            count = 0
            for recipe in recipes:
                if self._add_recipe(recipe, source="api_import"):
                    count += 1
            
            logger.info(f"✅ Successfully imported {count}/{len(recipes)} recipes from API")
            return count
            
        except requests.RequestException as e:
            logger.error(f"❌ API request error: {e}")
            return 0
        except json.JSONDecodeError as e:
            logger.error(f"❌ Invalid API response format: {e}")
            return 0
        except Exception as e:
            logger.error(f"❌ Error fetching from API: {e}")
            return 0
    
    def clone_from_preset(self, preset_file: str = None) -> int:
        """
        Clone công thức từ preset_recipes.json
        
        Args:
            preset_file: Đường dẫn file preset (default: assets/data/preset_recipes.json)
            
        Returns:
            Số công thức được thêm thành công
        """
        if preset_file is None:
            # Tìm file preset từ project root
            preset_file = os.path.join(
                os.path.dirname(os.path.dirname(__file__)),
                "assets/data/preset_recipes.json"
            )
        
        logger.info(f"📋 Cloning from preset recipes: {preset_file}")
        return self.clone_from_json(preset_file)
    
    def add_manual_recipe(self, 
                         title: str,
                         description: str,
                         ingredients: List[str],
                         steps: List[str],
                         duration: int,
                         recipe_type: str = "Khác",
                         image_url: str = "") -> bool:
        """
        Thêm công thức thủ công
        
        Args:
            title: Tên công thức
            description: Mô tả
            ingredients: Danh sách nguyên liệu
            steps: Các bước nấu
            duration: Thời gian nấu (phút)
            recipe_type: Loại công thức
            image_url: URL hình ảnh
            
        Returns:
            True nếu thêm thành công, False nếu thất bại
        """
        recipe = {
            "title": title,
            "description": description,
            "ingredients": ingredients,
            "steps": steps,
            "durationInMinutes": duration,
            "type": recipe_type,
            "imageUrl": image_url
        }
        
        return self._add_recipe(recipe, source="manual_input")
    
    def _add_recipe(self, recipe_data: Dict[str, Any], source: str = "unknown") -> bool:
        """
        Thêm công thức vào database
        
        Args:
            recipe_data: Dữ liệu công thức
            source: Nguồn gốc (json_import, api_import, manual_input)
            
        Returns:
            True nếu thêm thành công, False nếu thất bại
        """
        try:
            # Validate dữ liệu bắt buộc
            if not recipe_data.get('title'):
                logger.warning(f"⚠️ Skipping recipe: missing title")
                return False
            
            # Chuẩn bị dữ liệu
            title = recipe_data['title']
            description = recipe_data.get('description', '')
            duration = recipe_data.get('durationInMinutes', 30)
            recipe_type = recipe_data.get('type', 'Khác')
            image_url = recipe_data.get('imageUrl', '')
            ingredients = recipe_data.get('ingredients', [])
            steps = recipe_data.get('steps', [])
            
            # Convert steps to JSON string
            steps_json = json.dumps(steps, ensure_ascii=False) if steps else json.dumps([])
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Kiểm tra công thức đã tồn tại chưa (theo title)
            cursor.execute('SELECT id FROM recipes WHERE title = ?', (title,))
            if cursor.fetchone():
                logger.warning(f"⚠️ Recipe already exists: {title}")
                conn.close()
                return False
            
            # Thêm công thức
            cursor.execute('''
                INSERT INTO recipes 
                (title, imageUrl, description, steps, durationInMinutes, type, source, cloned_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                title, image_url, description, steps_json, duration, 
                recipe_type, source, datetime.now().isoformat()
            ))
            
            recipe_id = cursor.lastrowid
            
            # Thêm nguyên liệu
            for ingredient in ingredients:
                cursor.execute('''
                    INSERT INTO ingredients (recipeId, name, isChecked)
                    VALUES (?, ?, 0)
                ''', (recipe_id, ingredient))
            
            conn.commit()
            conn.close()
            
            logger.info(f"✅ Recipe added: {title} (ID: {recipe_id}, {len(ingredients)} ingredients)")
            return True
            
        except sqlite3.IntegrityError as e:
            logger.error(f"❌ Database integrity error: {e}")
            return False
        except Exception as e:
            logger.error(f"❌ Error adding recipe: {e}")
            return False
    
    def list_all_recipes(self) -> List[Dict]:
        """
        Liệt kê tất cả công thức
        
        Returns:
            Danh sách công thức với ingredients
        """
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute('SELECT * FROM recipes')
            recipes = cursor.fetchall()
            
            result = []
            for recipe in recipes:
                recipe_dict = dict(recipe)
                
                # Lấy nguyên liệu
                cursor.execute(
                    'SELECT * FROM ingredients WHERE recipeId = ?',
                    (recipe_dict['id'],)
                )
                ingredients = [dict(ing) for ing in cursor.fetchall()]
                recipe_dict['ingredients'] = ingredients
                
                # Parse steps
                recipe_dict['steps'] = json.loads(recipe_dict['steps'])
                
                result.append(recipe_dict)
            
            conn.close()
            return result
            
        except Exception as e:
            logger.error(f"❌ Error listing recipes: {e}")
            return []
    
    def get_statistics(self) -> Dict:
        """
        Lấy thống kê
        
        Returns:
            Dict chứa thống kê
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Tổng số công thức
            cursor.execute('SELECT COUNT(*) FROM recipes')
            total_recipes = cursor.fetchone()[0]
            
            # Công thức theo loại
            cursor.execute('''
                SELECT type, COUNT(*) as count 
                FROM recipes 
                GROUP BY type
            ''')
            by_type = {row[0]: row[1] for row in cursor.fetchall()}
            
            # Công thức theo nguồn
            cursor.execute('''
                SELECT source, COUNT(*) as count 
                FROM recipes 
                GROUP BY source
            ''')
            by_source = {row[0]: row[1] for row in cursor.fetchall()}
            
            # Tổng nguyên liệu
            cursor.execute('SELECT COUNT(*) FROM ingredients')
            total_ingredients = cursor.fetchone()[0]
            
            conn.close()
            
            return {
                "total_recipes": total_recipes,
                "by_type": by_type,
                "by_source": by_source,
                "total_ingredients": total_ingredients
            }
            
        except Exception as e:
            logger.error(f"❌ Error getting statistics: {e}")
            return {}
    
    def clear_all(self) -> bool:
        """
        Xóa tất cả công thức (CẢNH BÁO!)
        
        Returns:
            True nếu thực hiện thành công
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('DELETE FROM ingredients')
            cursor.execute('DELETE FROM recipes')
            
            conn.commit()
            conn.close()
            
            logger.warning(f"⚠️ All recipes and ingredients have been deleted")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error clearing database: {e}")
            return False


# ===== CLI Tool =====

def main():
    """CLI interface cho RecipeCloner"""
    
    print("""
    ╔════════════════════════════════════════╗
    ║     🍳 COOKBOOK RECIPE CLONER TOOL     ║
    ╚════════════════════════════════════════╝
    """)
    
    cloner = RecipeCloner()
    
    while True:
        print("\n📋 Menu:")
        print("1. 📂 Clone từ JSON file")
        print("2. 🌐 Clone từ API")
        print("3. 📋 Clone từ Preset recipes")
        print("4. ✏️  Thêm công thức thủ công")
        print("5. 📊 Xem thống kê")
        print("6. 📖 Liệt kê tất cả công thức")
        print("7. 🗑️  Xóa tất cả (CẢNH BÁO!)")
        print("0. ❌ Thoát")
        
        choice = input("\n👉 Chọn (0-7): ").strip()
        
        if choice == '1':
            json_file = input("Nhập đường dẫn file JSON: ").strip()
            count = cloner.clone_from_json(json_file)
            print(f"\n✅ Đã thêm {count} công thức")
        
        elif choice == '2':
            api_url = input("Nhập URL API: ").strip()
            count = cloner.clone_from_api(api_url)
            print(f"\n✅ Đã thêm {count} công thức")
        
        elif choice == '3':
            count = cloner.clone_from_preset()
            print(f"\n✅ Đã thêm {count} công thức từ preset")
        
        elif choice == '4':
            title = input("Tên công thức: ").strip()
            description = input("Mô tả: ").strip()
            duration = int(input("Thời gian nấu (phút): ") or "30")
            recipe_type = input("Loại (VD: Việt Nam, Á Đông): ").strip() or "Khác"
            
            ingredients_input = input("Nguyên liệu (cách nhau bằng dấu ;): ").strip()
            ingredients = [i.strip() for i in ingredients_input.split(';') if i.strip()]
            
            steps_input = input("Các bước (cách nhau bằng dấu ;): ").strip()
            steps = [s.strip() for s in steps_input.split(';') if s.strip()]
            
            if cloner.add_manual_recipe(
                title, description, ingredients, steps, duration, recipe_type
            ):
                print("\n✅ Công thức đã được thêm")
            else:
                print("\n❌ Lỗi khi thêm công thức")
        
        elif choice == '5':
            stats = cloner.get_statistics()
            print("\n📊 Thống kê:")
            print(f"   Tổng công thức: {stats.get('total_recipes', 0)}")
            print(f"   Tổng nguyên liệu: {stats.get('total_ingredients', 0)}")
            print("\n   Theo loại:")
            for rtype, count in stats.get('by_type', {}).items():
                print(f"      - {rtype}: {count}")
            print("\n   Theo nguồn:")
            for source, count in stats.get('by_source', {}).items():
                print(f"      - {source}: {count}")
        
        elif choice == '6':
            recipes = cloner.list_all_recipes()
            print(f"\n📖 Danh sách {len(recipes)} công thức:")
            for i, recipe in enumerate(recipes, 1):
                print(f"\n{i}. {recipe['title']}")
                print(f"   Loại: {recipe['type']}")
                print(f"   Thời gian: {recipe['durationInMinutes']} phút")
                print(f"   Nguyên liệu: {len(recipe['ingredients'])}")
                print(f"   Bước: {len(recipe['steps'])}")
        
        elif choice == '7':
            confirm = input("⚠️  Bạn chắc chắn muốn xóa tất cả? (yes/no): ").strip().lower()
            if confirm == 'yes':
                if cloner.clear_all():
                    print("✅ Đã xóa tất cả")
                else:
                    print("❌ Lỗi khi xóa")
            else:
                print("❌ Đã hủy")
        
        elif choice == '0':
            print("\n👋 Tạm biệt!")
            break
        
        else:
            print("❌ Lựa chọn không hợp lệ")


if __name__ == "__main__":
    main()
