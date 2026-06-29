# 🛠️ Deployment & Usage Manual

This manual provides the step-by-step technical instructions required to provision, deploy, manage, and verify the 4-tier observability pipeline on your host machine.

---

## 📋 1. Prerequisites & Host Provisioning

### A. Update Package Indices & Install Build Core
Run the following commands to synchronize repository lists and install the primary C++ compilation toolchain, system routing services, and container orchestration runtimes:

```bash
# 1. Update the local repository package indexes
sudo apt-get update

# 2. Install the necessary C++ compiler tools and CMake engine
sudo apt-get install -y g++ cmake make

# 3. Install the primary log routing service engine
sudo apt-get install -y syslog-ng

# 4. Install the runtime engine plugin 
sudo apt-get install -y docker-compose-v2
```

### B. Pre-Flight System Verification Checks
Execute these status commands before proceeding to confirm that your core system engines are running and healthy:
```bash
# Check Docker Service state
sudo systemctl status docker --no-pager

# Check Syslog-NG Service state
sudo systemctl status syslog-ng --no-pager
```

### C. Host Filesystem & Authorization Setup
Manually initialize all six dedicated file paths under `/var/log/` and adjust ownership and permission bitmasks so the `syslog` daemon can write logs without permission errors:

```bash
# 1. Force create all 6 targeted log files manually on the host filesystem
sudo touch /var/log/kernel_syslogng.log /var/log/app_kernel_syslogng.log
sudo touch /var/log/app_kernel_formatted.log /var/log/app_kernel_json.log
sudo touch /var/log/kernel_formatted.log /var/log/kernel_json.log

# 2. Change ownership to the syslog system group
sudo chown syslog:adm /var/log/*kernel*.log /var/log/*syslogng*.log

# 3. Grant read/write rights directly to the daemon engine
sudo chmod 662 /var/log/*kernel*.log /var/log/*syslogng*.log
```

---

## ⚙️ 2. Build & Run the Routing Engine

### A. Compile C++ Code & Install syslog-ng Build Objects
Generate the application environment via CMake, build the artifact templates, and automatically install the routing engine blocks directly into the systemd environment:

```bash
# 1. Access the local workspace build directory
mkdir -p build && cd build

# 2. Clean out old caching traces completely
rm -rf *

# 3. Run CMake generation and compilation
cmake ..
cmake --build .

# 4. Install the newly generated configuration file directly into /etc/syslog-ng/conf.d/
sudo cmake --install .

# 5. Verify the syntax to make sure no errors exist
sudo syslog-ng -s

# 6. Restart the daemon service to load your modular rules
sudo systemctl restart syslog-ng
```

### B. Compile & Run the Containerized App Simulator
Build the target Docker image and map the host’s `/dev/log` domain socket via an absolute volume bridge to push container telemetry safely back out to the host OS layers:

```bash
# 7. Compile the Docker image from the Dockerfile recipe
sudo docker build -t app_syslog_container .

# 8. Run the application container with the host's logging socket mounted
sudo docker run --rm -v /dev/log:/dev/log app_syslog_container
```

---

## 🧪 3. Output Verification & Live Tailing

Verify that the `syslog-ng` filters are active by tracking the raw, formatted, and structured logs inside your host console:

```bash
# Check C++ application text logs matching UTC ISO-8601 parameters
sudo tail -f /var/log/app_kernel_formatted.log

# Check C++ application JSON data logs
sudo cat /var/log/app_kernel_json.log

# Check real-time Linux kernel hardware logs
sudo tail -f /var/log/kernel_formatted.log
```

### Optional Cleanup Script (Log Truncation)
To truncate and wipe file histories cleanly during ongoing performance profiling cycles:
```bash
sudo truncate -s 0 /var/log/app_kernel_*.log /var/log/kernel_*.log
```

---

## 🎛️ 4. Dynamic Runtime Severity Filtering

You can test pipeline performance dynamically by changing log visibility thresholds using the standard Linux syslog severity matrix:

| Code ID | Severity Name | Operational Description |
| :--- | :--- | :--- |
| **0** | `emerg` | Emergency: System is unusable |
| **1** | `alert` | Alert: Action must be taken immediately |
| **2** | `crit` | Critical conditions |
| **3** | `err` | Error conditions |
| **4** | `warning` | Warning conditions |
| **5** | `notice` | Normal but significant conditions |
| **6** | `info` | Informational messages |
| **7** | `debug` | Debug-level messages |

#### Strategy A: Bind to a Specific Severity Level
```bash
sudo sed -i 's/level(.*)/level(warn);/' /etc/syslog-ng/conf.d/00-loglevel.conf && sudo systemctl reload syslog-ng
```

#### Strategy B: Bind to an Inclusive Sliding Range
```bash
sudo sed -i 's/level([^)]*)/level(debug..emerg)/' /etc/syslog-ng/conf.d/00-loglevel.conf && sudo syslog-ng -s && sudo systemctl reload syslog-ng
```

---

## 📊 5. Grafana Cloud-Native Ingestion Stack

### A. Grafana Core Engine Setup
Follow the standard distribution engine steps provided in the official [Grafana Installation Guide](https://grafana.com).

### B. Grafana Loki Installation & Configuration

```bash
# 1. Add keyrings, pull signatures, and install the Loki engine
mkdir -p /etc/apt/keyrings/
wget -q -O - https://grafana.com | gpg --dearmor > /etc/apt/keyrings/grafana.gpg
sudo chmod 644 /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt-get update && sudo apt-get install -y loki

# 2. Provision essential directory dependencies
sudo mkdir -p /etc/loki /var/lib/loki /var/log/loki
```

Open your main server configuration properties file (`sudo nano /etc/loki/config.yaml`) and apply the following parameters:

```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  instance_addr: 127.0.0.1
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

# Crucial fixes for Loki v3 Standalone crashing
frontend:
  scheduler_address: ""
  
query_range:
  align_queries_with_step: true
  cache_results: false

limits_config:
  allow_structured_metadata: true

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h
```

Now, map Loki to systemd (`sudo nano /etc/systemd/system/loki.service`):

```ini
[Unit]
Description=Loki Log Datastore Engine
After=network.target

[Service]
ExecStart=/usr/bin/loki -config.file /etc/loki/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
```

Initialize and launch the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl start loki
sudo systemctl status loki
```

---

### C. Grafana Alloy Collection Agent Setup

```bash
# 1. Map cryptographic package dependencies
sudo apt install -y gpg
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/grafana.asc https://grafana.com/gpg-full.key
sudo chmod 644 /etc/apt/keyrings/grafana.asc
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt-get update && sudo apt-get install -y alloy
```

Open the agent’s orchestration manifest (`sudo nano /etc/alloy/config.alloy`) and add the pipeline scrapers:

```alloy
// 1. Discover the target log files on the local disk (JSON and Formatted Streams)
local.file_match "syslog" {
  path_targets = [
    { "__path__" = "/var/log/app_kernel_json.log", job = "syslogng_app_json", host = "localhost" },
    { "__path__" = "/var/log/app_kernel_formatted.log", job = "syslogng_app_fmt", host = "localhost" },
    { "__path__" = "/var/log/kernel_json.log", job = "syslogng_kernel_json", host = "localhost" }
  ]
}

// 2. CORRECTED PIPELINE FLOW: Scrapes files and ships them through the relabeler stage
loki.source.file "logs" {
  targets    = local.file_match.syslog.targets
  forward_to = [loki.write.local.receiver]
}

// 3. Send the labeled log packets straight to the local Loki port
loki.write "local" {
  endpoint {
    url = "http://localhost:3100/loki/api/v1/push"
  }
}
```

Bind the telemetry stream to systemd (`sudo nano /etc/systemd/system/alloy.service`):

```ini
[Unit]
Description=Grafana Alloy Telemetry Scraping Pipeline
After=network.target loki.service

[Service]
ExecStart=/usr/bin/alloy run /etc/alloy/config.alloy
Restart=always

[Install]
WantedBy=multi-user.target
```

Reload the units and bring the scraper online:
```bash
sudo systemctl daemon-reload
sudo systemctl enable alloy
sudo systemctl start alloy
sudo systemctl status alloy
```

---

## 🖥️ 6. End-to-End Grafana UI Connection

1. Open your web browser and navigate to the active Grafana endpoint interface (Defaults to `http://localhost:3000`).
2. Use the left-hand navigation menu to head into **Connections** ➡️ **Data Sources**.
3. Select Add data source, choose Loki, and append your target engine link address: http://localhost:3100.
4. Click Save & Test. Once verified, switch to the Explore panel to search and visualize logs across your entire multi-format dashboard!
