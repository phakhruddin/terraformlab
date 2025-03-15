import logging
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Function triggered via HTTP request.")

    name = req.params.get("name")
    if not name:
        try:
            req_body = req.get_json()
            name = req_body.get("name")
        except ValueError:
            pass

    if name:
        return func.HttpResponse(f"Hello, {name}!")
    else:
        return func.HttpResponse(
            "Please pass a name in the query string or request body",
            status_code=400
        )
