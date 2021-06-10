#!/usr/bin/env python3

import os
from time import time
from typing import List

import boto3
from flask import Flask
from mcstatus import MinecraftServer

app = Flask(__name__)

NAMESPACE = 'GameServers/Minecraft'
SERVER_NAME = os.environ.get('SERVER_NAME', 'Minecraft')
TIMEOUT = os.environ.get('TIMEOUT', 900)

start_time = time()

cloudwatch = boto3.client('cloudwatch')


def uptime():
    return time() - start_time


def create_metric(name: str, value, unit=None, dimensions={}):
    metric = {
        'MetricName': name,
        'Dimensions': [
            {
                'Name': 'ServerName',
                'Value': SERVER_NAME
            },
        ],
        'Value': value
    }

    for name, value in dimensions.items():
        metric['Dimensions'].append({
            'Name': name,
            'Value': value
        })

    if unit:
        metric['Unit'] = value

    return metric


def send_metrics(metrics: List[dict]):
    cloudwatch.put_metric_data(
        Namespace=NAMESPACE,
        MetricData=metrics
    )


def server_metrics():
    try:
        server = MinecraftServer.lookup("localhost:25565")
        status = server.status()
    except (OSError, ConnectionRefusedError) as e:
        send_metrics([create_metric('Status', 0)])

        # With over a hundred mods Minecraft will take more than 5 minutes to
        # start up. The AWS NLB healthcheck grace period has a maximum time of
        # 5 minutes so we return a false positive until TIMEOUT is reached.

        if uptime() < TIMEOUT:
            return f"Server is starting up: {e}"

        return f"Server is offline: {e}", 500

    latency = status.latency
    player_count = status.players.online

    metrics = []
    metrics.append(create_metric('Status', 1))
    metrics.append(create_metric('Latency', latency, 'Milliseconds'))
    metrics.append(create_metric('PlayerCount', player_count))
    send_metrics(metrics)

    return f"The server has {player_count} players and replied in {latency} ms"


@app.route('/')
def ping():
    return server_metrics()
