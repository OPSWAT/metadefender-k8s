import json
import logging
import requests
import os
import azure.functions as func


def main(event: func.EventGridEvent):
    data = event.get_json()
    geturl = event.get_json()['url']
    tolist=geturl.split("/")
    name = "/".join(tolist[3:])
    for key, value in list(data.items()):
        if key == "url":
            data.update({'name': name})
    logging.info('Python EventGrid trigger processed an event: %s', name)
    requests.post(os.getenv('APIENDPOINT', ""), headers={'ApiKey':os.getenv('APIKEY', "")}, json ={'Metadata': json.dumps(data), 'storageClientId': os.getenv('STORAGECLIENTID', "") })
