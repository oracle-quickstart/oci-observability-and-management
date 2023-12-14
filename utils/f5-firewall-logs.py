import os
import random
from datetime import datetime, timedelta

current_time = datetime.utcnow()
formatted_time = current_time.strftime("%b %d %H:%M:%S")
log_message = f"{formatted_time} XXXX_F5_DMZXX err dcc[11457]: 9999999999:9: [SECEV] Request blocked, violations: Web scraping detected. HTTP protocol compliance sub violations: N/A. Evasion techniques sub violations: N/A. Web services security sub violations: N/A. Virus name: N/A. Support id: 99999999999999999, source ip: 192.168.1.100, xff ip: N/A, source port: 99999, destination ip: 203.128.45.67, destination port: 999, route_domain: 200, HTTP classifier: /Common/www.xxxxxxxxx.yy.http, scheme HTTPS, geographic location: <RU>, request: <GET /ns/xxxxxx.yyy?id_seccion=9999 HTTP/1.1\r\nContent-Length: 0\r\nCookie: XXXXXXXX_XXXXXXXXX=d8b78f937f6f9d569cda500fd5cae49>, username: <8117.1533970714@MAILCATCH.COM>, session_id: <d9ba5ea0f4e98df0>"

file_name = 'f5-firewall-logs.log'
if os.path.exists(file_name):
    os.remove(file_name)

with open(file_name, 'a') as f:
  f.write(log_message)
f.close()
