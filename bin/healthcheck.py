#!/usr/bin/env python3

import sys

import boto3
from mcstatus import MinecraftServer

NAMESPACE = 'GameServers/Minecraft'
SERVER_NAME = 'ConnectivityTest'

cloudwatch = boto3.client('cloudwatch')

def send_status(value: int):
    cloudwatch.put_metric_data(
        Namespace=NAMESPACE,
        MetricData=[
            {
                'MetricName': 'Status',
                'Dimensions': [
                    {
                        'Name': 'ServerName',
                        'Value': SERVER_NAME
                    },
                ],
                'Value': value
            },
        ]
    )

try:
    server = MinecraftServer.lookup("localhost:25565")
    status = server.status()
except (OSError, ConnectionRefusedError) as e:
    print(f"Server is offline: {e}")
    send_status(0)
    sys.exit(0)

send_status(1)

cloudwatch.put_metric_data(
    Namespace=NAMESPACE,
    MetricData=[
        {
            'MetricName': 'Latency',
            'Dimensions': [
                {
                    'Name': 'ServerName',
                    'Value': SERVER_NAME
                },
            ],
            'Value': status.latency,
            'Unit': 'Milliseconds'
        },
    ]
)

cloudwatch.put_metric_data(
    Namespace=NAMESPACE,
    MetricData=[
        {
            'MetricName': 'PlayerCount',
            'Dimensions': [
                {
                    'Name': 'ServerName',
                    'Value': SERVER_NAME
                },
            ],
            'Value': status.players.online
        },
    ]
)
