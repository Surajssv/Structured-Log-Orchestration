# Structured-Log-Orchestration
This project is to get the lifecycle of application and system logs,moving from isolated container runtimes to central cloud-native dashboards using syslog-ng, Grafana Alloy, Loki, and Grafana.

### Architecture Diagram:
```mermaid
graph TD
    %% Styling and Theme definitions
    classDef layerFill fill:#1e1e24,stroke:#3a3a4a,stroke-width:2px,color:#fff;
    classDef componentFill fill:#2d3142,stroke:#4f5d75,stroke-width:1px,color:#bfc0c0;
    classDef filterFill fill:#ef8354,stroke:#bfc0c0,stroke-width:1px,color:#fff;
    classDef outputFill fill:#4f5d75,stroke:#2d3142,stroke-width:1px,color:#fff;

    %% Subgraphs for Layers
    subgraph LAYER1 ["1. GENERATION LAYER (Guest Containers / Hardened Kernels)"]
        CPP["C++ Application Loop<br/>(POSIX syslog API)"]
        KERN["Linux Kernel Core<br/>(Hardware/AppArmor Events)"]
        DEVLOG["/dev/log<br/>(Bridged via Docker Volume)"]
        KMSG["/proc/kmsg"]
    end
    class LAYER1 layerFill;

    subgraph LAYER2 ["2. AGGREGATION LAYER (Operating System Core)"]
        JOURNALD["systemd-journald<br/>(Indexed Binary Database)"]
    end
    class LAYER2 layerFill;

    subgraph LAYER3 ["3. PROCESSING & ROUTING LAYER (syslog-ng Engine)"]
        SYSLONG["syslog-ng Core<br/>(Master Source: s_src)"]
        FILT_APP["Filter: Application <br/>(program == 'app_kernel_syslogng')"]
        FILT_KERN["Filter: Kernel <br/>(facility == 'kern')"]
        
        R1["Raw Logs"]
        F1["Format Logs"]
        J1["JSON Logs"]
        
        R2["Raw Logs"]
        F2["Format Logs"]
        J2["JSON Logs"]
    end
    class LAYER3 layerFill;

    subgraph LAYER4 ["4. VISUALIZATION LAYER (Grafana Observability Stack)"]
        FILES["/var/log/*.log<br/>(Monitored in real-time)"]
        ALLOY["Alloy<br/>(File Scraping Agent)"]
        LOKI["Loki<br/>(Log Datastore Engine)"]
        GRAFANA["Grafana<br/>(Web UI Observability Dashboard)"]
    end
    class LAYER4 layerFill;

    %% Connections
    CPP --> DEVLOG
    KERN --> KMSG
    DEVLOG --> JOURNALD
    KMSG --> JOURNALD
    JOURNALD --> SYSLONG
    
    SYSLONG --> FILT_APP
    SYSLONG --> FILT_KERN
    
    FILT_APP --> R1
    FILT_APP --> F1
    FILT_APP --> J1
    
    FILT_KERN --> R2
    FILT_KERN --> F2
    FILT_KERN --> J2
    
    J1 -.-> FILES
    J2 -.-> FILES
    FILES --> ALLOY
    ALLOY -- "HTTP LogQL Push" --> LOKI
    LOKI --> GRAFANA

    %% Apply Classes
    class CPP,KERN,DEVLOG,KMSG,JOURNALD,SYSLONG,FILES,ALLOY,LOKI,GRAFANA componentFill;
    class FILT_APP,FILT_KERN filterFill;
    class R1,F1,J1,R2,F2,J2 outputFill;
```
### Architecture Overview:

*   **Layer 1: Generation Layer**
    *   **C++ Application:** Loops continuously, sending logging text using standard POSIX `syslog` calls.
    *   **Linux Kernel:** Captures low-level security violations (AppArmor) and driver messages at `/proc/kmsg`.
    *   **Docker Isolation Bridge:** Maps `/dev/log` out of the container so the host can process isolation events safely.

*   **Layer 2: Aggregation Layer**
    *   **systemd-journald:** The central nervous system for host logs. It catches payloads from both kernel space and user space, converting them into structured, indexed binary journal blocks.

*   **Layer 3: Processing & Routing Layer**
    *   **syslog-ng Engine:** Reads directly from the systemd journal via `s_src`.
    *   **Conditional Filters:** Evaluates operational scopes dynamically (`program` vs `facility`) to split traffic cleanly.
    *   **Multiplexed Destinations:** Outputs data into three formats at once. 
        *   **Raw Logs:** Intact, unmodified historical string payloads.
        *   **Formatted Logs:** Cleaned, human-readable standard text for immediate terminal inspection.
        *   **JSON Logs (`*_json.log`):** Structured key-value text maps, specifically generated to support clean, queryable ingestion at scale.
          
*   **Layer 4: Dual-Stream Monitoring & Visualization Layer**
    *   **Unified Local Streams:** All three log streams (**Raw**, **Formatted**, and **JSON**) are generated actively under `/var/log/`. This allows developers and sysadmins to tail, track, and contrast text patterns locally for rapid terminal troubleshooting.
    *   **Grafana Alloy Ecosystem Ingestion:** Rather than isolating a single format, Grafana Alloy targets these log types from the `/var/log/` file paths simultaneously.
    *   **Multi-Format Loki Store:** Ingests the complete contextual streams via HTTP LogQL pushes. This allows the cloud stack to store exact raw history alongside highly queryable structured properties.
    *   **Grafana UI Overview:** Renders full visualization metrics across all telemetry variations, ensuring full data audit capability from a single dashboard.
 
## 📂 Repository Layout
```text
├── config/
│   ├── syslog-ng.conf.in   # Master routing engine configurations and filters
│   └── 00-loglevel.conf.in # Dynamic Log Level filteration
├── src/
│   └── main.cpp            # C++ telemetry application loop simulation
├── CMakeLists.txt          # CMake
├── Dockerfile              # Application Container building instruction recipe
├── DEVELOPMENT.md          # Complete, step-by-step setup & deployment guide
└── README.md               # Pipeline overview and architecture
```

## 🚀 Quick Start
Ready to build and deploy this infrastructure? 

👉 **[Click here to view the step-by-step Deployment & Setup Guide (DEVELOPMENT.md)](./DEVELOPMENT.md)**
