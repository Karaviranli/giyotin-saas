FROM python:3.11-slim

WORKDIR /app

# Sistem paketleri
RUN apt-get update && apt-get install -y gcc libpq-dev && rm -rf /var/lib/apt/lists/*

# Dosyaları tek tek kopyalayalım
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama kodlarını kopyala (Dizin yapısını koruyarak)
COPY ./backend/app /app/app

ENV PATH="/home/root/.local/bin:${PATH}"

CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]