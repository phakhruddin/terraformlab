import logging
import azure.functions as func

def main(msg: func.QueueMessage) -> None:
    message_body = msg.get_body().decode('utf-8')
    logging.info(f"Processing task: {message_body}")