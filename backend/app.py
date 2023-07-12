import os
import psycopg2
from flask import Flask, render_template

app = Flask(__name__)

def get_db_connection():
    conn = psycopg2.connect(host='localhost',
                            database=os.environ['POSTGRES_DB_NAME'],
                            user=os.environ['POSTGRES_USER'],
                            password=os.environ['POSTGRES_PASSWORD'],
                            port=5433
                            )
    return conn


@app.route('/')
def index():
    conn = get_db_connection()
    return 'lmao'
