import os
import json
import argparse
import sys

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


def save_recipes_to_json(recipes, out_path):
    """
    Save recipes (list/dict) to out_path as pretty JSON with UTF-8 encoding.
    """
    out_dir = os.path.dirname(out_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(recipes, f, ensure_ascii=False, indent=4)


# --- Internet fetch helpers ---
try:
    import requests
except Exception:
    requests = None

try:
    from bs4 import BeautifulSoup
except Exception:
    BeautifulSoup = None


def fetch_json(url, timeout=10):
    """Fetch JSON from URL. Returns Python object or raises."""
    if requests:
        resp = requests.get(url, timeout=timeout)
        resp.raise_for_status()
        return resp.json()
    # fallback to urllib
    from urllib.request import urlopen, Request
    req = Request(url, headers={"User-Agent": "python-urllib/3"})
    with urlopen(req, timeout=timeout) as r:
        return json.load(r)


def fetch_html_minimal(url, timeout=10):
    """
    Fetch HTML and extract minimal recipe-like data:
    - title: h1 or <title>
    - description: meta[name=description] or first <p>
    - imageUrl: meta[property='og:image'] if present
    Returns list with a single recipe dict (so shape matches RECIPES_DATA).
    """
    if requests:
        resp = requests.get(url, timeout=timeout, headers={"User-Agent": "bot/1.0"})
        resp.raise_for_status()
        content = resp.text
    else:
        from urllib.request import urlopen, Request
        req = Request(url, headers={"User-Agent": "python-urllib/3"})
        with urlopen(req, timeout=timeout) as r:
            content = r.read().decode(errors="ignore")

    title = None
    description = None
    image = None

    if BeautifulSoup:
        soup = BeautifulSoup(content, "html.parser")
        h1 = soup.find("h1")
        title = h1.get_text(strip=True) if h1 else (soup.title.string.strip() if soup.title and soup.title.string else None)
        meta_desc = soup.find("meta", attrs={"name": "description"})
        if meta_desc and meta_desc.get("content"):
            description = meta_desc.get("content").strip()
        else:
            p = soup.find("p")
            description = p.get_text(strip=True) if p else None
        og = soup.find("meta", property="og:image")
        if og and og.get("content"):
            image = og.get("content").strip()
    else:
        # Very small fallback parsing
        import re
        m = re.search(r"<h1[^>]*>(.*?)</h1>", content, re.I | re.S)
        if m:
            title = re.sub(r"<[^>]+>", "", m.group(1)).strip()
        m = re.search(r'<meta\s+name=["\']description["\']\s+content=["\'](.*?)["\']', content, re.I | re.S)
        if m:
            description = m.group(1).strip()
        m = re.search(r'<meta\s+property=["\']og:image["\']\s+content=["\'](.*?)["\']', content, re.I | re.S)
        if m:
            image = m.group(1).strip()

    recipe = {
        "title": title or url,
        "description": description or "",
        "imageUrl": image or "",
        "durationInMinutes": 0,
        "type": "Từ web",
        "ingredients": [],
        "steps": [],
    }
    return [recipe]


def fetch_from_internet(url, mode="auto"):
    """
    mode: 'auto' (try JSON then HTML), 'json', or 'html'
    Returns list/dict suitable for save_recipes_to_json.
    """
    if mode not in ("auto", "json", "html"):
        raise ValueError("mode must be one of auto|json|html")
    if mode in ("auto", "json"):
        try:
            data = fetch_json(url)
            # if top-level object is single recipe dict, wrap in list
            if isinstance(data, dict):
                return [data]
            return data
        except Exception:
            if mode == "json":
                raise
            # fallback to html
    # HTML extraction
    return fetch_html_minimal(url)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Save recipes to JSON (local or from internet).")
    parser.add_argument("--url", "-u", help="URL to fetch (JSON API or webpage)")
    parser.add_argument("--mode", "-m", choices=["auto", "json", "html"], default="auto", help="Fetch mode")
    parser.add_argument("--out", "-o", default=r"d:\cookbook\data\recipes.json", help="Output JSON path")
    args = parser.parse_args()

    if args.url:
        try:
            data = fetch_from_internet(args.url, mode=args.mode)
        except Exception as e:
            print("Error fetching from URL:", e, file=sys.stderr)
            sys.exit(1)
    else:
        data = RECIPES_DATA

    save_recipes_to_json(data, args.out)
    print(f"Saved recipes to: {args.out}")