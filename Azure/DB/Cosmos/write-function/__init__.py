import logging
import azure.functions as func
import pymongo
import os
import json

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Received a request to insert data into Cosmos DB.")

    try:
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid JSON payload", status_code=400)

    connection_string = os.environ["COSMOS_CONNECTION_STRING"]
    client = pymongo.MongoClient(connection_string)
    database = client["deen-mongo-db"]
    collection = database["deen-collection"]

    collection.insert_one(req_body)
    
    return func.HttpResponse(f"Data inserted: {json.dumps(req_body)}", status_code=200)