import os
import random
from datetime import datetime, timedelta

current_time = datetime.utcnow() - timedelta(minutes=10)
formatted_time = current_time.strftime("%m/%d/%Y %I:%M:%S %p")
event_str = f"{formatted_time} 03B4 EVENT 192.168.1.10 The DNS server has started."
ips = ['10.0.0.5', '192.168.2.20', '192.168.2.2', '10.1.1.1']
sockets = [336, 336, 328, 2688]
remote_addrs = ['::1', '::1', '192.168.1.2', '192.168.1.2']
ports = [64329, 64329, 37325, 53]
packet_str = ''

def choice_and_remove(list):
  random_element = random.choice(list)
  list.remove(random_element)
  return random_element

def get_random_values():
  return {
    'ip': choice_and_remove(ips),
    'socket': choice_and_remove(sockets),
    'remote_addr': choice_and_remove(remote_addrs),
    'port': choice_and_remove(ports)
  }

for i in range(4):
  current_time += timedelta(seconds=random.randint(1, 120))
  formatted_time = current_time.strftime("%m/%d/%Y %I:%M:%S %p")
  random_values = get_random_values()
  packet_str += f'''\n{formatted_time} 00DC PACKET {random_values['ip']}  00000000016B80A0 UDP Rcv ::1             9ebb   Q [0001   D   NOERROR] SOA    (5)xyztu(4)labs(0)
  UDP question info at 00000000016B80A0
    Socket = {random_values['socket']}
    Remote addr {random_values['remote_addr']}, port {random_values['port']}
    Time Query=588068, Queued=0, Expire=0
    Buf length = 0x0fa0 (4000)
    Msg length = 0x001c (28)
    Message:
      XID       0x9ebb
      Flags     0x0100
        QR        0 (QUESTION)
        OPCODE    0 (QUERY)
        AA        0
        TC        0
        RD        1
        RA        0
        Z         0
        CD        0
        AD        0
        RCODE     0 (NOERROR)
      QCOUNT    1
      ACOUNT    0
      NSCOUNT   0
      ARCOUNT   0
      QUESTION SECTION:
      Offset = 0x000c, RR count = 0
      Name      "(5)xyztu(4)labs(0)"
        QTYPE   SOA (6)
        QCLASS  1
      ANSWER SECTION:
        empty
      AUTHORITY SECTION:
        empty
      ADDITIONAL SECTION:
        empty'''

logs = f'{event_str}{packet_str}'
file_name = 'microsoft-dns-server-logs.log'

if os.path.exists(file_name):
    os.remove(file_name)

with open(file_name, 'a') as f:
  f.write(logs)
f.close()
