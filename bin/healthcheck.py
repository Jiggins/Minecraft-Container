#!/usr/bin/env python3

import logging
import os
from time import time
from typing import List

import boto3
from botocore.exceptions import NoCredentialsError
from flask import Flask
from mcstatus import MinecraftServer
from rcon import Client

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())

app = Flask(__name__)

NAMESPACE = 'GameServers/Minecraft'
SERVER_NAME = os.environ.get('SERVER_NAME', 'Minecraft')
TIMEOUT = os.environ.get('TIMEOUT', 900)

start_time = time()

cloudwatch = boto3.client('cloudwatch', os.environ.get('AWS_REGION', 'eu-west-1'))


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
        metric['Unit'] = unit

    return metric


def send_metrics(metrics: List[dict]):
    try:
        cloudwatch.put_metric_data(
            Namespace=NAMESPACE,
            MetricData=metrics
        )
    except NoCredentialsError:
        logger.warning("No AWS credentials found, logging metrics to stdout")
        [logger.info(metric) for metric in metrics]


def server_tps():
    metrics = []

    with Client('127.0.0.1', 25575, passwd='hunter2') as client:
        response = client.run('forge tps')

        for dimension in response.strip().split('\n'):
            stats = dimension.split()

            # The final line of the response gives an overall latency/TPS for all dimensions
            if stats[0] == 'Overall:':
                name = stats[0]
                tick_time = float(stats[4])
                tps = float(stats[8])
            else:
                name = stats[1]
                tick_time = float(stats[6])
                tps = float(stats[10])

            metrics.append(create_metric('Tick Time', tick_time, unit='Milliseconds', dimensions={'dimension': name}))
            metrics.append(create_metric('TPS', tps, unit=None, dimensions={'dimension': name}))

    send_metrics(metrics)


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

    server_tps()

    return f"The server has {player_count} players and replied in {latency} ms"


@app.route('/')
def ping():
    return server_metrics()
