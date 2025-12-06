from supabase import create_client, Client
from dotenv import load_dotenv
import os

# Load environment variables from .env
load_dotenv()

# Fetch Supabase credentials
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print(f"🔗 Connecting to Supabase: {SUPABASE_URL}")


def insert_recipe(title, description, image_url, duration_minutes, recipe_type):
    """Insert a recipe and return its ID"""
    try:
        data = supabase.table("preset_recipes").insert({
            "title": title,
            "description": description,
            "image_url": image_url,
            "duration_minutes": duration_minutes,
            "type": recipe_type,
        }).execute()

        recipe_id = data.data[0]["id"]
        print(f"✅ Recipe '{title}' inserted with ID: {recipe_id}")
        return recipe_id
    except Exception as e:
        print(f"❌ Failed to insert recipe: {e}")
        return None


def insert_ingredient(recipe_id, ingredient_name):
    """Insert an ingredient for a recipe"""
    try:
        supabase.table("preset_ingredients").insert({
            "recipe_id": recipe_id,
            "name": ingredient_name,
        }).execute()
        print(f"  ✓ Ingredient '{ingredient_name}' added")
    except Exception as e:
        print(f"  ❌ Failed to insert ingredient: {e}")


def insert_step(recipe_id, step_text, step_order):
    """Insert a cooking step for a recipe"""
    try:
        supabase.table("preset_steps").insert({
            "recipe_id": recipe_id,
            "step_text": step_text,
            "step_order": step_order,
        }).execute()
        print(f"  ✓ Step {step_order}: {step_text}")
    except Exception as e:
        print(f"  ❌ Failed to insert step: {e}")


def upload_recipes(recipes_data):
    """Upload recipes to database"""
    try:
        for recipe in recipes_data:
            print(f"\n📝 Processing recipe: {recipe['title']}")

            # Insert recipe
            recipe_id = insert_recipe(
                recipe['title'],
                recipe.get('description', ''),
                recipe.get('imageUrl', ''),
                recipe.get('durationInMinutes', 0),
                recipe.get('type', 'Thức ăn')
            )

            if recipe_id:
                # Insert ingredients
                for ingredient in recipe.get('ingredients', []):
                    insert_ingredient(recipe_id, ingredient['name'])

                # Insert steps
                for idx, step in enumerate(recipe.get('steps', []), 1):
                    insert_step(recipe_id, step, idx)

        print("\n✅ All recipes uploaded successfully!")

    except Exception as e:
        print(f"\n❌ Upload failed: {e}")


# Sample recipes data
RECIPES_DATA = [
    {
        "title": "Phở Bò",
        "description": "Phở bò truyền thống Việt Nam",
        "imageUrl": "assets/images/banh-mi-bo-toi-1-600x400.jpg",
        "durationInMinutes": 120,
        "type": "Thức ăn",
        "ingredients": [
            {"name": "500g thịt bò"},
            {"name": "200g bánh phở"},
            {"name": "2 quả hành"},
            {"name": "1 miếng gừng"},
            {"name": "2 thìa mắm cá"},
        ],
        "steps": [
            "Luộc thịt bò trong 90 phút",
            "Nấu nước dùng với gừng và hành",
            "Xếp bánh phở vào tô",
            "Đổ nước dùng nóng vào",
            "Thêm thịt bò và rau thơm",
        ],
    },
    {
        "title": "Cơm Tấm Sườn Nướng",
        "description": "Cơm tấm sườn nướng với trứng ốp",
        "imageUrl": "assets/images/cach-lam-ga-sot-cam.jpg",
        "durationInMinutes": 45,
        "type": "Thức ăn",
        "ingredients": [
            {"name": "300g cơm tấm"},
            {"name": "200g sườn lợn"},
            {"name": "1 quả trứng gà"},
            {"name": "100g dưa leo"},
            {"name": "50g cà chua"},
        ],
        "steps": [
            "Nướng sườn trên lửa than 20 phút",
            "Chiên trứng trong dầu",
            "Cắt dưa leo thành lát mỏng",
            "Xếp cơm lên đĩa",
            "Xếp topping: sườn, trứng, dưa leo",
        ],
    },
    {
        "title": "Bánh Mì Thịt Nướng",
        "description": "Bánh mì nóng với thịt nướng",
        "imageUrl": "assets/images/cach-nau-pho-bo.jpg",
        "durationInMinutes": 30,
        "type": "Thức ăn",
        "ingredients": [
            {"name": "1 bánh mì baguette"},
            {"name": "200g thịt lợn nướng"},
            {"name": "50g dưa muối"},
            {"name": "50g cà rốt"},
            {"name": "2 thìa mayonnaise"},
        ],
        "steps": [
            "Nướng thịt lợn 15 phút",
            "Cắt bánh mì dọc theo giữa",
            "Thoa mayonnaise vào hai mặt",
            "Xếp thịt lợn, dưa muối, cà rốt",
            "Gói lại bằng giấy",
        ],
    },
    {
        "title": "Nước Cam Tươi",
        "description": "Nước cam ép tươi lạnh",
        "imageUrl": "assets/images/salad-trai-cay-khong-nuoc-sot-thumbnail-3.jpg",
        "durationInMinutes": 10,
        "type": "Đồ uống",
        "ingredients": [
            {"name": "5 quả cam"},
            {"name": "100ml nước lọc"},
            {"name": "2 thìa đường"},
            {"name": "Đá lạnh"},
        ],
        "steps": [
            "Rửa sạch cam",
            "Cắt cam đôi",
            "Ép cam lấy nước",
            "Trộn với nước lọc và đường",
            "Thêm đá lạnh và khuấy đều",
        ],
    },
]


def main():
    print("🚀 Starting recipe upload...\n")

    try:
        # Kiểm tra kết nối
        if not SUPABASE_URL or not SUPABASE_KEY:
            raise Exception("SUPABASE_URL or SUPABASE_KEY not found in .env")

        # Upload recipes
        upload_recipes(RECIPES_DATA)

    except Exception as e:
        print(f"\n❌ Error: {e}")


if __name__ == "__main__":
    main()