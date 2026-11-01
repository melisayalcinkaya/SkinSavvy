FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /srv

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app ./app

# Root olmayan kullanıcıyla çalış.
RUN useradd --create-home --uid 10001 api && mkdir -p /data && chown api /data
USER api

ENV ENVIRONMENT=production DATABASE_URL=sqlite:////data/skinsavvy.db PORT=8000
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --proxy-headers --forwarded-allow-ips='*'"]
