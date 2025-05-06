import requests

url = "http://192.168.86.103/event/by/keyid"
payload = {
    "msg": "Hello World",
    "from": "Connor's Laptop"
}

#response = requests.post(url, json=payload)
#response = requests.post(url, json=payload, verify=False) # for self-signed https
print("Response Code:", response.status_code)
