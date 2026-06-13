#!/usr/bin/env python3
"""SEO route'lari + IndexNow key route'unu nginx config'e ekler (idempotent)."""
from pathlib import Path

p = Path("/etc/nginx/sites-enabled/kaviragiyotin")
text = p.read_text()

# Onceki bozuk eklemelerden temizle
import re
text = re.sub(
    r"    # GENERATED SEO ROUTES.*?\n    \}\n",
    "",
    text,
    flags=re.DOTALL,
)
text = re.sub(
    r"    # IndexNow.*?\n    \}\n",
    "",
    text,
    flags=re.DOTALL,
)

# Yeni route'lari ekle
routes = r"""    # IndexNow key catch-all (Bing/Yandex verification icin)
    location ~ "^/[0-9a-fA-F]+\.txt$" {
        root /var/www/kaviragiyotin/landing;
        default_type text/plain;
    }

    # GENERATED SEO ROUTES - 16 yeni landing sayfasi
    location ~ "^/tedarikci/([a-z0-9\-]+)$" {
        root /var/www/kaviragiyotin/landing;
        try_files /tedarikci/$1.html =404;
        add_header Cache-Control "public, max-age=3600";
    }
    location ~ "^/(giyotin\-[a-z0-9\-]+|isi-camli-giyotin|silinebilir-giyotin)$" {
        root /var/www/kaviragiyotin/landing;
        try_files /$1.html =404;
        add_header Cache-Control "public, max-age=3600";
    }
"""

target = "    location = /app {"
if target in text and "GENERATED SEO ROUTES" not in text:
    text = text.replace(target, routes + "\n" + target)
    p.write_text(text)
    print("Tum route'lar eklendi")
else:
    if "GENERATED SEO ROUTES" in text:
        print("Routes zaten var")
    else:
        print(f"HATA: target bulunamadi: {target}")
