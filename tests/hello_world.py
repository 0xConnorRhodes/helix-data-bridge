import requests

url = "http://192.168.86.103/event/by/keyid"
payload = {
    "msg": "Hello World",
    "from": "Connor's Laptop"
}

response = requests.post(url, json=payload)
print("Response Code:", response.status_code)
