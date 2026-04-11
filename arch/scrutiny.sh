#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR=/opt/scrutiny/config
INFLUXDB_DIR=/opt/scrutiny/influxdb
WRAPPER=/usr/local/bin/smartctl-wrapper

# --- Copy configs ---
sudo cp .config/smartmontools/smartctl-wrapper.sh "$WRAPPER"
sudo chmod +x "$WRAPPER"
sudo mkdir -p "$CONFIG_DIR" "$INFLUXDB_DIR"
sudo cp .config/smartmontools/collector.yml "$CONFIG_DIR/"

# --- Recreate container if needed ---
if docker inspect scrutiny &>/dev/null; then
  echo "Removing existing scrutiny container..."
  docker rm -f scrutiny
fi

docker run -d \
  --name scrutiny \
  --cap-add SYS_RAWIO \
  --device /dev/sda \
  --device /dev/nvme0 \
  --device /dev/nvme1 \
  -p 9090:8080 \
  -v /run/udev:/run/udev:ro \
  -v /opt/scrutiny/config:/opt/scrutiny/config \
  -v /opt/scrutiny/influxdb:/opt/scrutiny/influxdb \
  -v /usr/local/bin/smartctl-wrapper:/usr/local/bin/smartctl-wrapper:ro \
  --restart unless-stopped \
  ghcr.io/analogj/scrutiny:master-omnibus

echo "Waiting for scrutiny to be ready..."
until curl -sf http://localhost:9090/api/health &>/dev/null; do
  sleep 2
done

echo "Collecting initial metrics..."
docker exec scrutiny /opt/scrutiny/bin/scrutiny-collector-metrics run

echo "Done. Dashboard: http://localhost:9090"
