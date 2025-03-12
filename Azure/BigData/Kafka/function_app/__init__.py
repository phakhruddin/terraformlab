import logging
import azure.functions as func

def main(event: func.EventHubEvent):
    message_body = event.get_body().decode('utf-8')
    logging.info(f"Received Kafka message: {message_body}")