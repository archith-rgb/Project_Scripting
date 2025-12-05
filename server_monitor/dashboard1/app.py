
from flask import Flask, render_template, jsonify
import os

app = Flask(__name__)

LOG_FILE = "/home/reddy/server_monitor/server_monitor.log"

def get_logs(limit=30):
    if not os.path.exists(LOG_FILE):
        return []
    
    with open(LOG_FILE, "r") as f:
        lines = f.readlines()[-limit:]

    data = []
    for line in lines:
        try:
            parts = line.split("|")
                
            if len(parts) < 5:
                continue

                
            timestamp = parts[0].strip()

            # CPU : extract only the FIRST number
            cpu_raw = parts[1].split(":")[1]
            cpu_val = ''.join([c for c in cpu_raw if c.isdigit() or c == '.'])
            if len(cpu_val) > 5:         # If weird double numbers like 0.000.00 fix it
                cpu_val = cpu_val[:len(cpu_val)//2]
            cpu = float(cpu_val)

            # MEM
            mem_raw = parts[2].split(":")[1]
            mem = float(mem_raw.replace("%", "").strip())

            # DISK
            disk_raw = parts[3].split(":")[1]
            disk = float(disk_raw.replace("%", "").strip())

            # LATENCY
            lat_raw = parts[4].split(":")[1]
            lat_clean = (
                lat_raw.replace("msms", "")
                       .replace("ms", "")
                       .replace(" ", "")
                       .strip()
            )
            lat = float(lat_clean)

            data.append({
                "timestamp": timestamp,
                "cpu": cpu,
                "mem": mem,
                "disk": disk,
                "latency": lat
            })

        except Exception as e:
            print("Parse error:", e)
            continue

    return data

@app.route("/")
def index():
    return render_template("index1.html")

@app.route("/api/logs")
def api_logs():
    return jsonify(get_logs())

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
