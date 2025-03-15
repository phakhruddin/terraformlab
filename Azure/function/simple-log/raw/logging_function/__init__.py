import logging
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("This is a test log message from the Python function!")
    return func.HttpResponse("Function executed. Check logs in Application Insights.", status_code=200)