"""Updates a Route 53 record with the current IP address"""

import datetime
import os
import socket
import time

import boto3
import requests

# Validate environment
DNS_NAME = "DNS_NAME"
if DNS_NAME not in os.environ:
    raise RuntimeError("%s missing from environment" % DNS_NAME)
DNS_NAME = os.environ[DNS_NAME]

AWS_ACCESS_KEY_ID = "AWS_ACCESS_KEY_ID"
if AWS_ACCESS_KEY_ID not in os.environ:
    raise RuntimeError("%s missing from environment" % AWS_ACCESS_KEY_ID)
AWS_ACCESS_KEY_ID = os.environ[AWS_ACCESS_KEY_ID]

AWS_SECRET_ACCESS_KEY = "AWS_SECRET_ACCESS_KEY"
if AWS_SECRET_ACCESS_KEY not in os.environ:
    raise RuntimeError("%s missing from environment" % AWS_SECRET_ACCESS_KEY)
AWS_SECRET_ACCESS_KEY = os.environ[AWS_SECRET_ACCESS_KEY]

AWS_R53_ZONEID = "AWS_R53_ZONEID"
if AWS_R53_ZONEID not in os.environ:
    raise RuntimeError("%s missing from environment" % AWS_R53_ZONEID)
AWS_R53_ZONEID = os.environ[AWS_R53_ZONEID]

LOOP_TIME = 600
if 'LOOP_TIME' in os.environ:
    LOOP_TIME = int(os.environ['LOOP_TIME'])

# It's handy to know it all works first time though
FIRST_LOOP = True


if __name__ == "__main__":
    while True:
        DATE_TIME = datetime.datetime.today().strftime('%Y-%m-%d %H:%M')

        # Get current DNS record
        try:
            CURRENT_DNS = socket.gethostbyname(DNS_NAME)
        except:  # pylint: disable=bare-except
            # Failed to lookup DNS - not connected to the Internet?  Or does the name not exist yet?
            # Lets assume the later... no harm in that
            CURRENT_DNS = None

        # Get current IP
        try:
            RESP = requests.get('http://httpbin.org/ip')
            CURRENT_IP = RESP.json()['origin']
        except:  # pylint: disable=bare-except
            print("Failed to lookup IP - not connected to the Internet?  httpbin.org down?")
            time.sleep(LOOP_TIME)
            continue

        if FIRST_LOOP:
            print("Current DNS record: %s" % CURRENT_DNS)
            print("Current public IP : %s" % CURRENT_IP)
            FIRST_LOOP = False

        if CURRENT_DNS != CURRENT_IP:
            # Update
            R53 = boto3.client('route53')
            CHANGE_SET = R53.change_resource_record_sets(
                HostedZoneId=AWS_R53_ZONEID,
                ChangeBatch={
                    'Changes': [
                        {
                            'Action': 'UPSERT',
                            'ResourceRecordSet': {
                                'Name': DNS_NAME,
                                'Type': 'A',
                                'TTL': 300,
                                'ResourceRecords': [
                                    {
                                        'Value': CURRENT_IP,
                                    }
                                ]
                            }
                        }
                    ]
                }
            )
            print("%s: DNS change ID %s submitted to AWS" % (DATE_TIME, CHANGE_SET['ChangeInfo']['Id']))

        time.sleep(LOOP_TIME)
