#!/usr/bin/env python3
"""
P-Trainer mağaza ekran görüntüsü çerçeveleme aracı.

Ham ekran görüntülerini profesyonel mağaza görseline dönüştürür:
- Gradient arka plan
- Telefon çerçevesi efekti (rounded corners + shadow)
- Başlık ve alt yazı metinleri

Kullanım:
  1. docs/store-listing/screenshots/raw/ klasörüne ham SS'leri koyun
  2. python3 docs/store-listing/generate_screenshots.py
  3. Çıktılar docs/store-listing/screenshots/framed/ klasöründe oluşur

Gereksinim: pip install Pillow
"""

import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
except ImportError:
    print("Pillow gerekli: pip install Pillow")
    sys.exit(1)

# ── Ayarlar ──
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(SCRIPT_DIR, "screenshots", "raw")
OUT_DIR = os.path.join(SCRIPT_DIR, "screenshots", "framed")

# iPhone 6.7" çıktı boyutu
OUTPUT_W, OUTPUT_H = 1290, 2796

# Telefon ekranı çerçeve boyutu (çıktı içindeki)
PHONE_W, PHONE_H = 1050, 2280
PHONE_RADIUS = 60

# Ekran görüntüleri ve başlıkları (dosya_adı: (başlık, alt_yazı))
SCREENS_TR = {
    "01_login.png": ("Güvenli Giriş", "Şifreli giriş sistemi ile\nverileriniz güvende"),
    "02_home.png": ("Ana Menü", "Tüm özelliklerinize\ntek dokunuşla erişin"),
    "03_athletes.png": ("Sporcularım", "Sporcularınızı kolayca\nyönetin ve takip edin"),
    "04_detail.png": ("Sporcu Detayı", "Periyot, ders ve ödeme\nbilgilerini görüntüleyin"),
    "05_weekly.png": ("Haftalık Plan", "Haftanın her günü için\nders programınız"),
    "06_period.png": ("Periyot Takibi", "Ders ve yoklama\nkayıtlarınız"),
}

SCREENS_EN = {
    "01_login.png": ("Secure Login", "Password-protected\naccess to your data"),
    "02_home.png": ("Home Menu", "Access all features\nwith a single tap"),
    "03_athletes.png": ("My Athletes", "Easily manage and\ntrack your athletes"),
    "04_detail.png": ("Athlete Detail", "View periods, lessons\nand payment info"),
    "05_weekly.png": ("Weekly Plan", "Your lesson schedule\nfor every day"),
    "06_period.png": ("Period Tracking", "Lesson and attendance\nrecords"),
}

# Gradient renkleri (turkuaz tema)
GRAD_TOP = (0, 188, 212)      # #00BCD4
GRAD_BOTTOM = (0, 137, 123)   # #00897B

# Alternatif gradient'ler her ekran için
GRADIENTS = [
    ((0, 137, 123), (0, 188, 212)),       # Teal → Cyan
    ((0, 188, 212), (3, 169, 244)),       # Cyan → Blue
    ((30, 136, 229), (66, 165, 245)),     # Blue shades
    ((0, 137, 123), (76, 175, 80)),       # Teal → Green
    ((255, 179, 0), (255, 193, 7)),       # Amber → Yellow
    ((156, 39, 176), (206, 147, 216)),    # Purple shades
]


def create_gradient(width, height, color_top, color_bottom):
    """Dikey gradient arka plan oluştur."""
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        ratio = y / height
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * ratio)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * ratio)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    return img


def round_corners(img, radius):
    """Resme yuvarlatılmış köşeler ekle."""
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, img.size[0], img.size[1]], radius=radius, fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def add_shadow(img, offset=(0, 15), blur_radius=30, shadow_color=(0, 0, 0, 80)):
    """Resme gölge efekti ekle."""
    shadow_size = (
        img.size[0] + blur_radius * 2,
        img.size[1] + blur_radius * 2,
    )
    shadow = Image.new("RGBA", shadow_size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [blur_radius, blur_radius,
         blur_radius + img.size[0], blur_radius + img.size[1]],
        radius=PHONE_RADIUS,
        fill=shadow_color,
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur_radius))
    return shadow


def get_font(size, bold=False):
    """Sistem fontu yükle."""
    font_paths = [
        # macOS
        "/System/Library/Fonts/SFPro-Bold.otf" if bold else "/System/Library/Fonts/SFPro-Regular.otf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
        # Fallback
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for path in font_paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def frame_screenshot(raw_path, output_path, title, subtitle, gradient_index=0):
    """Ham ekran görüntüsünü çerçevele."""
    # Arka plan gradient
    grad_top, grad_bottom = GRADIENTS[gradient_index % len(GRADIENTS)]
    bg = create_gradient(OUTPUT_W, OUTPUT_H, grad_top, grad_bottom)
    bg = bg.convert("RGBA")

    # Başlık yazısı
    title_font = get_font(72, bold=True)
    sub_font = get_font(42)

    draw = ImageDraw.Draw(bg)

    # Başlık — üstte
    title_y = 140
    bbox = draw.textbbox((0, 0), title, font=title_font)
    title_w = bbox[2] - bbox[0]
    draw.text(
        ((OUTPUT_W - title_w) // 2, title_y),
        title,
        fill=(255, 255, 255),
        font=title_font,
    )

    # Alt yazı
    sub_y = title_y + 100
    for line in subtitle.split("\n"):
        bbox = draw.textbbox((0, 0), line, font=sub_font)
        line_w = bbox[2] - bbox[0]
        draw.text(
            ((OUTPUT_W - line_w) // 2, sub_y),
            line,
            fill=(255, 255, 255, 200),
            font=sub_font,
        )
        sub_y += 56

    # Ekran görüntüsünü yükle ve boyutlandır
    try:
        screenshot = Image.open(raw_path).convert("RGBA")
    except Exception as e:
        print(f"  ⚠️  Dosya açılamadı: {raw_path} — {e}")
        return False

    screenshot = screenshot.resize((PHONE_W, PHONE_H), Image.LANCZOS)

    # Köşeleri yuvarla
    screenshot = round_corners(screenshot, PHONE_RADIUS)

    # Gölge
    shadow = add_shadow(screenshot)
    phone_x = (OUTPUT_W - PHONE_W) // 2
    phone_y = OUTPUT_H - PHONE_H - 120

    shadow_x = phone_x - 30
    shadow_y = phone_y - 15
    bg.paste(shadow, (shadow_x, shadow_y), shadow)

    # Ekran görüntüsünü yapıştır
    bg.paste(screenshot, (phone_x, phone_y), screenshot)

    # Kaydet
    bg.save(output_path, "PNG", quality=95)
    print(f"  ✅ {os.path.basename(output_path)}")
    return True


def generate_all(lang="tr"):
    """Tüm ekran görüntülerini çerçevele."""
    screens = SCREENS_TR if lang == "tr" else SCREENS_EN
    raw_dir = os.path.join(RAW_DIR, lang) if os.path.isdir(os.path.join(RAW_DIR, lang)) else RAW_DIR
    out_dir = os.path.join(OUT_DIR, lang)
    os.makedirs(out_dir, exist_ok=True)

    print(f"\n🖼  Ekran görüntüleri çerçeveleniyor ({lang.upper()})...")
    print(f"   Kaynak: {raw_dir}")
    print(f"   Çıktı:  {out_dir}\n")

    count = 0
    for i, (filename, (title, subtitle)) in enumerate(screens.items()):
        raw_path = os.path.join(raw_dir, filename)
        if not os.path.exists(raw_path):
            print(f"  ⏭  {filename} bulunamadı, atlanıyor")
            continue
        out_path = os.path.join(out_dir, f"framed_{filename}")
        if frame_screenshot(raw_path, out_path, title, subtitle, gradient_index=i):
            count += 1

    print(f"\n✅ {count} ekran görüntüsü oluşturuldu → {out_dir}")
    return count


def generate_feature_graphic():
    """Google Play Feature Graphic (1024x500) oluştur."""
    W, H = 1024, 500
    bg = create_gradient(W, H, GRAD_TOP, GRAD_BOTTOM).convert("RGBA")
    draw = ImageDraw.Draw(bg)

    # Logo ikonu
    icon_path = os.path.join(SCRIPT_DIR, "..", "..", "assets", "icon", "icon.png")
    if os.path.exists(icon_path):
        icon = Image.open(icon_path).convert("RGBA")
        icon = icon.resize((120, 120), Image.LANCZOS)
        bg.paste(icon, (80, (H - 120) // 2), icon)

    # Başlık
    title_font = get_font(64, bold=True)
    sub_font = get_font(32)

    draw.text((230, 150), "P-Trainer", fill=(255, 255, 255), font=title_font)
    draw.text(
        (230, 240),
        "Pilates Instructor's Best Companion",
        fill=(255, 255, 255, 200),
        font=sub_font,
    )
    draw.text(
        (230, 290),
        "Athlete Management • Lesson Plans • Payments",
        fill=(255, 255, 255, 160),
        font=sub_font,
    )

    out_path = os.path.join(OUT_DIR, "feature_graphic.png")
    os.makedirs(OUT_DIR, exist_ok=True)
    bg.save(out_path, "PNG")
    print(f"\n✅ Feature Graphic → {out_path}")


if __name__ == "__main__":
    os.makedirs(RAW_DIR, exist_ok=True)
    os.makedirs(OUT_DIR, exist_ok=True)

    # Ham SS'ler var mı kontrol et
    raw_files = []
    for d in [RAW_DIR, os.path.join(RAW_DIR, "tr"), os.path.join(RAW_DIR, "en")]:
        if os.path.isdir(d):
            raw_files.extend(os.listdir(d))

    if not any(f.endswith(".png") for f in raw_files):
        print("=" * 60)
        print("📸 HAM EKRAN GÖRÜNTÜLERİ GEREKLİ")
        print("=" * 60)
        print()
        print("Aşağıdaki adımları izleyin:")
        print()
        print("1. iPhone 16 Pro Max simülatörünü açın:")
        print("   flutter run -d 'iPhone 16 Pro Max'")
        print()
        print("2. Aşağıdaki ekranların SS'ini alın:")
        print("   (Simulator → File → Save Screen veya Cmd+S)")
        print()
        print("   01_login.png    — Giriş ekranı")
        print("   02_home.png     — Ana menü")
        print("   03_athletes.png — Sporcu listesi (2-3 örnek sporcu ile)")
        print("   04_detail.png   — Sporcu detay (periyot + ders saatleri)")
        print("   05_weekly.png   — Haftalık plan (dersler görünürken)")
        print("   06_premium.png  — Premium sayfası")
        print()
        print(f"3. SS'leri bu klasöre koyun:")
        print(f"   {RAW_DIR}/")
        print(f"   veya dil bazlı: {RAW_DIR}/tr/ ve {RAW_DIR}/en/")
        print()
        print("4. Bu scripti tekrar çalıştırın:")
        print("   python3 docs/store-listing/generate_screenshots.py")
        print()

        # Klasör yapısını oluştur
        os.makedirs(os.path.join(RAW_DIR, "tr"), exist_ok=True)
        os.makedirs(os.path.join(RAW_DIR, "en"), exist_ok=True)
        print(f"📁 Klasörler oluşturuldu: {RAW_DIR}/tr/ ve {RAW_DIR}/en/")
    else:
        # Ham SS'ler var, çerçevele
        generate_all("tr")
        generate_all("en")

    # Feature graphic her zaman oluştur
    generate_feature_graphic()
