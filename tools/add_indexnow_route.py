#!/usr/bin/env python3
"""IndexNow key catch-all route'unu nginx config'e ekler."""
from pathlib import Path

p = Path("/etc/nginx/sites-enabled/kaviragiyotin")
text = p.read_text()

if "IndexNow key catch-all" in text:
    print("Zaten var, atlandı")
else:
    route = (
        "    # IndexNow key catch-all (verification icin herhangi *.txt landing'den serve edilir)\n"
        "    location ~ ^/[0-9a-f]{16,64}\\.txt$ {\n"
        "        root /var/www/kaviragiyotin/landing;\n"
        "        default_type text/plain;\n"
        "    }\n"
    )
    target = "    # GENERATED SEO ROUTES"
    text = text.replace(target, route + target)
    p.write_text(text)
    print("Route eklendi")
