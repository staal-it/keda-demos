import logging
from time import sleep

import azure.functions as func

def main(msg: func.QueueMessage) -> None:
    logging.info('Start processing...')
    sleep(5)
    logging.info('Python queue trigger function processed a queue item: %s', msg.get_body().decode('utf-8'))
