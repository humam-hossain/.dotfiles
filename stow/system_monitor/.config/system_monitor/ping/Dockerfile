FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends iputils-ping iproute2 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY server.py ping_plot.html ./
RUN mkdir -p /app/data /app/logs
CMD ["python3", "server.py"]
