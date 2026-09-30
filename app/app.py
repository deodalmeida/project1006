import json
import os
import socket
from contextlib import closing

import boto3
import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)

REGION = os.environ.get("AWS_REGION", "us-east-1")
DB_HOST = os.environ["DB_HOST"]
DB_NAME = os.environ.get("DB_NAME", "appdb")
SECRET_ARN = os.environ["DB_SECRET_ARN"]


def get_database_secret():
    client = boto3.client("secretsmanager", region_name=REGION)
    response = client.get_secret_value(SecretId=SECRET_ARN)
    return json.loads(response["SecretString"])


def get_connection():
    secret = get_database_secret()
    return psycopg2.connect(
        host=DB_HOST,
        port=5432,
        dbname=DB_NAME,
        user=secret["username"],
        password=secret["password"],
        connect_timeout=5,
        sslmode="require",
    )


@app.get("/")
def index():
    return jsonify(
        project="aws-3tier-terraform-job-readiness",
        message="Application tier is healthy",
        hostname=socket.gethostname(),
    )


@app.get("/health")
def health():
    return jsonify(status="ok"), 200


@app.get("/db")
def database_check():
    try:
        with closing(get_connection()) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS visits (
                        id BIGSERIAL PRIMARY KEY,
                        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                        hostname TEXT NOT NULL
                    )
                    """
                )
                cur.execute(
                    "INSERT INTO visits(hostname) VALUES (%s)",
                    (socket.gethostname(),),
                )
                cur.execute("SELECT NOW(), COUNT(*) FROM visits")
                db_time, visits = cur.fetchone()
            conn.commit()

        return jsonify(
            status="connected",
            database_time=db_time.isoformat(),
            total_visits=visits,
            hostname=socket.gethostname(),
        )
    except Exception as exc:
        app.logger.exception("Database check failed")
        return jsonify(status="error", error=str(exc)), 500
