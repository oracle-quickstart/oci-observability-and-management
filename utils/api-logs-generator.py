import random
from datetime import datetime, timedelta

current_time = datetime.utcnow()
method = ["POST", "GET"]
username = ["livelabuser01", "Naman", "Jacob", "Riya", "livelabuser02"]
client_ip = ["::ffff:10.244.0.104", "::ffff:10.244.0.257", "::ffff:10.244.0.158", "::ffff:10.244.0.007", "::ffff:10.244.0.257"]
req_code = ["401", "200", "201", "304", "400", "404", "406", "409", "500", "503"]
content_length = random.randint(10,1000)

for i in range(1000): # 1000 random logs generated
    random_var_user_and_ip = random.randint(0,len(username)-1)
    # Generate a random number of seconds between 0 and 7200 (120 minutes)
    random_seconds = random.randint(0, 120*60)
    # Calculate the end time by subtracting random seconds from current time
    end_time_in_seconds = current_time - timedelta(seconds=random_seconds)
    # Random 1000 log records of 2 hours before current UTC time.
    end_time_in_proper_format = end_time_in_seconds.strftime('%d/%b/%Y:%T')
    log = client_ip[random_var_user_and_ip] + " - " + username[random_var_user_and_ip] + " [" + end_time_in_proper_format + " +0000] " + '"' + method[random.randint(0,len(method)-1)] + " /api/orders HTTP/1.1" + '" ' + req_code[random.randint(0,len(req_code)-1)] + " " + str(content_length) + ' "-" ' + '"python-requests/2.25.1"' + "\n"
    with open('livelab_logs.txt', 'a') as f:
        f.write(log)
    f.close()