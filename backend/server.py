import os
from flask import Flask, request, jsonify, session
from authlib.integrations.flask_oauth2 import ResourceProtector
from validator import Auth0JWTBearerTokenValidator
from sqlalchemy import create_engine
from dotenv import load_dotenv, find_dotenv
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, Session
from sqlalchemy import Text, ForeignKeyConstraint, select, insert, Boolean
from sqlalchemy.sql import func
import jwt
from flask_cors import CORS

load_dotenv(find_dotenv())
ALLOWED_EXTENSIONS = {'txt', 'pdf'}


class Base(DeclarativeBase):
    pass


class UserProfile(Base):
    __tablename__ = "user_profiles"
    user_id = mapped_column(Text, primary_key=True)
    email = mapped_column(Text, unique=True)
    verified = mapped_column(Boolean)


require_auth = ResourceProtector()
validator = Auth0JWTBearerTokenValidator(
    "dev-4et1s8fqfxunww8q.us.auth0.com",
    "gpt-doc-reader-api"
)
require_auth.register_token_validator(validator)
app = Flask(__name__)
app.secret_key = os.environ.get('SESSION_SECRET_KEY')
cors = CORS(app)


@app.route('/login', methods=['POST'])
@require_auth(None)
def login():
    engine = create_engine(f"postgresql+psycopg://{os.environ.get('SESSION_CREATOR_ROLE')}:" +
                           f"{os.environ.get('SESSION_CREATOR_PASSWORD')}@/gpt_doc_reader_postgres?host=localhost:5433")
    sqlalchemy_session = Session(engine)

    access_token = request.headers['authorization'][7:]
    access_token_payload = jwt.decode(access_token, options={"verify_signature": False})
    user_id = access_token_payload["sub"]
    email = access_token_payload["gpt-doc-reader/email"]

    user_already_exists_check = sqlalchemy_session.scalar(select(UserProfile).where(UserProfile.email == email))
    if not user_already_exists_check:
        new_user = UserProfile(email=email, user_id=user_id, verified=False)
        sqlalchemy_session.add(new_user)
    create_temp_access_user = func.create_temp_access_user(user_id, access_token)
    sqlalchemy_session.execute(create_temp_access_user)
    sqlalchemy_session.commit()

    return "", 200


@app.route('/add-user-to-database', methods=['POST'])
@require_auth(None)
def add_user_to_database():
    engine = create_engine(f"postgresql+psycopg://{os.environ.get('SESSION_CREATOR_ROLE')}:" +
                           f"{os.environ.get('SESSION_CREATOR_PASSWORD')}@/gpt_doc_reader_postgres?host=localhost:5433")
    sqlalchemy_session = Session(engine)

    access_token = request.headers['authorization'][7:]
    access_token_payload = jwt.decode(access_token, options={"verify_signature": False})
    user_id = access_token_payload["sub"]


    return "", 201


@app.route('/upload-file', methods=['POST'])
@require_auth(None)
def upload_file():
    access_token = request.headers['authorization'][7:]
    access_token_payload = jwt.decode(access_token, options={"verify_signature": False})
    email = access_token_payload["gpt-doc-reader/email"]

    engine = create_engine(f"postgresql+psycopg://{email}:" +
                           f"{access_token}@/gpt_doc_reader_postgres?host=localhost:5433")
    sqlalchemy_session = Session(engine)
    files = request.files
    for i in files:
        file = files[i]


@app.route('/get-user-info', methods=['GET'])
@require_auth(None)
def get_user_info():
    access_token = request.headers['authorization'][7:]
    access_token_payload = jwt.decode(access_token, options={"verify_signature": False})
    email = access_token_payload["gpt-doc-reader/email"]

    engine = create_engine(f"postgresql+psycopg://{email}:" +
                           f"{access_token}@/gpt_doc_reader_postgres?host=localhost:5433")
    sqlalchemy_session = Session(engine)

    profile = sqlalchemy_session.execute(select(UserProfile).where(UserProfile.email == email)).scalar_one()

    return profile.__dict__











    
