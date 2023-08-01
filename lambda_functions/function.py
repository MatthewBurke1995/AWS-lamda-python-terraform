import os
import requests

def main(event, context):
    try:    
        response = requests.get("https://catfact.ninja/fact")
        return response.json()
    except Exception as e:
        print(e)
        return {"error":e}
