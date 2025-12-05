"""
Web Scraper Cloner - Tool để clone công thức từ các website nấu ăn
Hỗ trợ scrape từ: Cooky, VnExpress, RecipeTin, AllRecipes, v.v.
"""

import os
import sys
import json
import sqlite3
import requests
from bs4 import BeautifulSoup
from datetime import datetime
from typing import List, Dict, Any, Optional
import logging
from urllib.parse import urljoin, urlparse

# Cấu hình logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class WebScraperCloner:
    """Tool để scrape công thức từ web và thêm vào database"""
    
    def __init__(self, db_path: str = "recipes.db"):
        """
        Khởi tạo WebScraperCloner
        
        Args:
            db_path: Đường dẫn đến database
        """
        self.db_path = db_path
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
        self._init_db()
        logger.info(f"✅ WebScraperCloner initialized with database: {db_path}")
    
    def _init_db(self):
        """Tạo tables nếu chưa tồn tại"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
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
            logger.info("📊 Database tables verified/created")
        except Exception as e:
            logger.error(f"❌ Error initializing database: {e}")
            raise
    
    def _add_recipe(self, recipe_data: Dict[str, Any], source_url: str = "web_scrape") -> bool:
        """
        Thêm công thức vào database
        
        Args:
            recipe_data: Dữ liệu công thức
            source_url: URL nguồn
            
        Returns:
            True nếu thêm thành công
        """
        try:
            if not recipe_data.get('title'):
                logger.warning(f"⚠️ Skipping recipe: missing title")
                return False
            
            title = recipe_data['title']
            description = recipe_data.get('description', '')
            duration = recipe_data.get('durationInMinutes', 30)
            recipe_type = recipe_data.get('type', 'Khác')
            image_url = recipe_data.get('imageUrl', '')
            ingredients = recipe_data.get('ingredients', [])
            steps = recipe_data.get('steps', [])
            
            steps_json = json.dumps(steps, ensure_ascii=False) if steps else json.dumps([])
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('SELECT id FROM recipes WHERE title = ?', (title,))
            if cursor.fetchone():
                logger.warning(f"⚠️ Recipe already exists: {title}")
                conn.close()
                return False
            
            cursor.execute('''
                INSERT INTO recipes 
                (title, imageUrl, description, steps, durationInMinutes, type, source, cloned_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                title, image_url, description, steps_json, duration, 
                recipe_type, source_url, datetime.now().isoformat()
            ))
            
            recipe_id = cursor.lastrowid
            
            for ingredient in ingredients:
                cursor.execute('''
                    INSERT INTO ingredients (recipeId, name, isChecked)
                    VALUES (?, ?, 0)
                ''', (recipe_id, ingredient))
            
            conn.commit()
            conn.close()
            
            logger.info(f"✅ Recipe added: {title} (ID: {recipe_id}, {len(ingredients)} ingredients)")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error adding recipe: {e}")
            return False
    
    # ===== Scraper Cooky.vn =====
    
    def scrape_cooky(self, recipe_url: str) -> Optional[Dict]:
        """
        Scrape công thức từ Cooky.vn
        
        Args:
            recipe_url: URL của công thức (vd: https://cooky.vn/recipe/12345)
            
        Returns:
            Dict chứa dữ liệu công thức
        """
        try:
            logger.info(f"🌐 Scraping Cooky: {recipe_url}")
            
            response = self.session.get(recipe_url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Lấy tiêu đề
            title_elem = soup.find('h1', class_=['title', 'recipe-title'])
            title = title_elem.text.strip() if title_elem else "Unknown"
            
            # Lấy mô tả
            desc_elem = soup.find(['meta[name="description"]', 'p', 'div'], class_=['description', 'intro'])
            description = desc_elem.get('content') if desc_elem.name == 'meta' else (
                desc_elem.text.strip() if desc_elem else ""
            )
            
            # Lấy hình ảnh
            img_elem = soup.find('img', class_=['recipe-image', 'main-image'])
            image_url = img_elem.get('src', '') if img_elem else ''
            
            # Lấy thời gian
            time_elem = soup.find(['span', 'div'], class_=['time', 'duration', 'cook-time'])
            duration = 30  # Default
            if time_elem:
                time_text = time_elem.text.lower()
                for word in time_text.split():
                    if word.isdigit():
                        duration = int(word)
                        break
            
            # Lấy nguyên liệu
            ingredients = []
            ingredients_section = soup.find(['ul', 'ol', 'div'], class_=['ingredients', 'ingredient-list', 'ingredients-list'])
            if ingredients_section:
                for item in ingredients_section.find_all(['li', 'p', 'div'], class_=['ingredient', 'ingredient-item']):
                    text = item.text.strip()
                    if text and text not in ingredients:
                        ingredients.append(text)
            
            # Lấy các bước
            steps = []
            steps_section = soup.find(['ol', 'div', 'ul'], class_=['steps', 'instructions', 'directions'])
            if steps_section:
                for item in steps_section.find_all(['li', 'p', 'div'], class_=['step', 'instruction', 'direction']):
                    text = item.text.strip()
                    if text and text not in steps:
                        steps.append(text)
            
            return {
                "title": title,
                "description": description[:200],  # Limit 200 chars
                "imageUrl": image_url,
                "durationInMinutes": duration,
                "type": "Việt Nam",
                "ingredients": ingredients[:20],  # Limit 20 ingredients
                "steps": steps[:15]  # Limit 15 steps
            }
            
        except Exception as e:
            logger.error(f"❌ Error scraping Cooky: {e}")
            return None
    
    # ===== Scraper RecipeTin.com =====
    
    def scrape_recipetin(self, recipe_url: str) -> Optional[Dict]:
        """
        Scrape công thức từ RecipeTin (hỗ trợ recipe có JSON-LD schema)
        
        Args:
            recipe_url: URL của công thức
            
        Returns:
            Dict chứa dữ liệu công thức
        """
        try:
            logger.info(f"🌐 Scraping RecipeTin: {recipe_url}")
            
            response = self.session.get(recipe_url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Tìm JSON-LD schema
            json_ld = soup.find('script', type='application/ld+json')
            if json_ld:
                try:
                    schema = json.loads(json_ld.string)
                    
                    title = schema.get('name', 'Unknown')
                    description = schema.get('description', '')[:200]
                    image_url = schema.get('image', {})
                    if isinstance(image_url, list):
                        image_url = image_url[0] if image_url else ''
                    
                    # Lấy thời gian
                    cook_time = schema.get('cookTime', 'PT30M')
                    duration = self._parse_iso_duration(cook_time)
                    
                    # Lấy nguyên liệu
                    ingredients = []
                    for ing in schema.get('recipeIngredient', []):
                        if ing and ing not in ingredients:
                            ingredients.append(ing)
                    
                    # Lấy các bước
                    steps = []
                    for step_obj in schema.get('recipeInstructions', []):
                        if isinstance(step_obj, dict):
                            step_text = step_obj.get('text', '')
                        else:
                            step_text = str(step_obj)
                        if step_text and step_text not in steps:
                            steps.append(step_text)
                    
                    return {
                        "title": title,
                        "description": description,
                        "imageUrl": image_url,
                        "durationInMinutes": duration,
                        "type": "Khác",
                        "ingredients": ingredients[:20],
                        "steps": steps[:15]
                    }
                
                except json.JSONDecodeError:
                    logger.warning("⚠️ Failed to parse JSON-LD schema")
            
            # Fallback: scrape HTML
            return self._scrape_html_fallback(soup, recipe_url)
            
        except Exception as e:
            logger.error(f"❌ Error scraping RecipeTin: {e}")
            return None
    
    def _parse_iso_duration(self, duration_str: str) -> int:
        """
        Parse ISO 8601 duration string (vd: PT30M, PT1H30M)
        
        Args:
            duration_str: ISO duration string
            
        Returns:
            Số phút
        """
        try:
            minutes = 0
            
            # Remove 'PT'
            duration_str = duration_str.replace('PT', '').upper()
            
            # Parse hours
            if 'H' in duration_str:
                hours_str = duration_str.split('H')[0]
                if hours_str:
                    minutes += int(hours_str) * 60
                duration_str = duration_str.split('H')[1]
            
            # Parse minutes
            if 'M' in duration_str:
                min_str = duration_str.split('M')[0]
                if min_str:
                    minutes += int(min_str)
            
            return max(minutes, 30)  # Minimum 30 minutes
            
        except:
            return 30
    
    def _scrape_html_fallback(self, soup: BeautifulSoup, url: str) -> Dict:
        """Fallback HTML scraping"""
        
        title = "Unknown"
        title_elem = soup.find(['h1', 'h2'])
        if title_elem:
            title = title_elem.text.strip()
        
        description = ""
        desc_elem = soup.find('p', class_=['description', 'intro'])
        if desc_elem:
            description = desc_elem.text.strip()[:200]
        
        image_url = ""
        img_elem = soup.find('img')
        if img_elem:
            image_url = img_elem.get('src', '')
            if image_url and not image_url.startswith('http'):
                image_url = urljoin(url, image_url)
        
        return {
            "title": title,
            "description": description,
            "imageUrl": image_url,
            "durationInMinutes": 30,
            "type": "Khác",
            "ingredients": [],
            "steps": []
        }
    
    # ===== Batch Scraper =====
    
    def scrape_multiple(self, urls: List[str], website: str = "auto") -> int:
        """
        Scrape nhiều URL
        
        Args:
            urls: Danh sách URLs
            website: Website (cooky, recipetin, auto)
            
        Returns:
            Số công thức được thêm thành công
        """
        logger.info(f"🌐 Scraping {len(urls)} URLs from {website}")
        
        count = 0
        for i, url in enumerate(urls, 1):
            logger.info(f"\n📍 [{i}/{len(urls)}] Processing: {url}")
            
            recipe = None
            
            if website == "cooky" or (website == "auto" and "cooky.vn" in url):
                recipe = self.scrape_cooky(url)
            elif website == "recipetin" or (website == "auto" and ("recipetin" in url or "allrecipes" in url)):
                recipe = self.scrape_recipetin(url)
            else:
                recipe = self.scrape_recipetin(url)  # Try default
            
            if recipe and self._add_recipe(recipe, source_url=website):
                count += 1
        
        logger.info(f"\n✅ Successfully scraped and added {count}/{len(urls)} recipes")
        return count
    
    def get_statistics(self) -> Dict:
        """Lấy thống kê"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('SELECT COUNT(*) FROM recipes')
            total_recipes = cursor.fetchone()[0]
            
            cursor.execute('''
                SELECT source, COUNT(*) as count 
                FROM recipes 
                GROUP BY source
            ''')
            by_source = {row[0]: row[1] for row in cursor.fetchall()}
            
            cursor.execute('SELECT COUNT(*) FROM ingredients')
            total_ingredients = cursor.fetchone()[0]
            
            conn.close()
            
            return {
                "total_recipes": total_recipes,
                "by_source": by_source,
                "total_ingredients": total_ingredients
            }
            
        except Exception as e:
            logger.error(f"❌ Error getting statistics: {e}")
            return {}


# ===== CLI Tool =====

def main():
    """CLI interface cho WebScraperCloner"""
    
    print("""
    ╔════════════════════════════════════════╗
    ║   🕷️  WEB SCRAPER CLONER TOOL          ║
    ║      Clone công thức từ web            ║
    ╚════════════════════════════════════════╝
    """)
    
    scraper = WebScraperCloner()
    
    while True:
        print("\n📋 Menu:")
        print("1. 🕷️  Scrape từ URL riêng lẻ")
        print("2. 📋 Scrape từ danh sách URLs")
        print("3. 📊 Xem thống kê")
        print("0. ❌ Thoát")
        
        choice = input("\n👉 Chọn (0-3): ").strip()
        
        if choice == '1':
            url = input("Nhập URL công thức: ").strip()
            if not url.startswith('http'):
                url = 'https://' + url
            
            website = input("Website (cooky/recipetin/auto) [auto]: ").strip() or "auto"
            
            recipe = None
            if "cooky.vn" in url:
                recipe = scraper.scrape_cooky(url)
            else:
                recipe = scraper.scrape_recipetin(url)
            
            if recipe:
                if scraper._add_recipe(recipe, source_url=website):
                    print("\n✅ Công thức đã được thêm")
                    print(f"   Tiêu đề: {recipe['title']}")
                    print(f"   Nguyên liệu: {len(recipe['ingredients'])}")
                    print(f"   Bước: {len(recipe['steps'])}")
                else:
                    print("\n⚠️ Công thức có thể đã tồn tại")
            else:
                print("\n❌ Lỗi khi scrape URL")
        
        elif choice == '2':
            url_file = input("Nhập đường dẫn file chứa danh sách URLs: ").strip()
            
            if not os.path.exists(url_file):
                print(f"❌ File không tìm thấy: {url_file}")
                continue
            
            try:
                with open(url_file, 'r', encoding='utf-8') as f:
                    urls = [line.strip() for line in f if line.strip() and line.startswith('http')]
                
                if not urls:
                    print("❌ Không có URLs hợp lệ trong file")
                    continue
                
                website = input("Website (cooky/recipetin/auto) [auto]: ").strip() or "auto"
                
                count = scraper.scrape_multiple(urls, website)
                
                stats = scraper.get_statistics()
                print(f"\n📊 Thống kê:")
                print(f"   Tổng công thức: {stats['total_recipes']}")
                print(f"   Tổng nguyên liệu: {stats['total_ingredients']}")
                
            except Exception as e:
                print(f"❌ Lỗi: {e}")
        
        elif choice == '3':
            stats = scraper.get_statistics()
            print(f"\n📊 Thống kê:")
            print(f"   Tổng công thức: {stats['total_recipes']}")
            print(f"   Tổng nguyên liệu: {stats['total_ingredients']}")
            print(f"\n   Theo nguồn:")
            for source, count in stats.get('by_source', {}).items():
                print(f"      - {source}: {count}")
        
        elif choice == '0':
            print("\n👋 Tạm biệt!")
            break
        
        else:
            print("❌ Lựa chọn không hợp lệ")


if __name__ == "__main__":
    main()
