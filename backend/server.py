import os
from dotenv import load_dotenv, find_dotenv

from flask import Flask, request, jsonify
from flask_cors import CORS
from authlib.integrations.flask_oauth2 import ResourceProtector

from sqlalchemy import create_engine, select
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session
import jwt

from validator import Auth0JWTBearerTokenValidator, allowed_file
from serialize import serialize_user_profile
from llm_logic import file_to_embedding, get_answer_from_chunks
from bucket_logic import upload_image_to_bucket
from models import File, UserProfile

load_dotenv(find_dotenv())


require_auth = ResourceProtector()
validator = Auth0JWTBearerTokenValidator(
    "dev-4et1s8fqfxunww8q.us.auth0.com",
    "gpt-doc-reader-api"
)

require_auth.register_token_validator(validator)
app = Flask(__name__)
app.secret_key = os.environ.get('SESSION_SECRET_KEY')
UPLOAD_FOLDER = os.path.abspath('uploads')
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
CORS(app)


def sql_session_init(username, password):
    connection_string = f"postgresql+psycopg://{username}:" + \
                        f"{password}@/gpt_doc_reader_postgres?host=localhost:5433"
    engine = create_engine(connection_string)
    sqlalchemy_session = Session(engine)
    return sqlalchemy_session


def get_id_token_and_email(req):
    access_token = req.headers['authorization'][7:]
    access_token_payload = jwt.decode(access_token, options={"verify_signature": False})
    user_id = access_token_payload["sub"]
    email = access_token_payload["gpt-doc-reader/email"]

    return user_id, access_token, email


@app.route('/login', methods=['POST'])
@require_auth(None)
def login():

    user_id, access_token, email = get_id_token_and_email(request)

    sqlalchemy_session = sql_session_init(os.environ.get("SESSION_CREATOR_ROLE"),
                                          os.environ.get("SESSION_CREATOR_PASSWORD"))

    insert_stmt = insert(UserProfile).values(email=email, user_id=user_id, verified=False)
    insert_stmt = insert_stmt.on_conflict_do_nothing()
    sqlalchemy_session.execute(insert_stmt)
    print(user_id)
    print(access_token)
    create_temp_access_user = func.create_temp_access_user(user_id, access_token)
    sqlalchemy_session.execute(create_temp_access_user)
    sqlalchemy_session.commit()

    return "", 200


@app.route('/upload-files', methods=['POST'])
@require_auth(None)
def upload_file():
    user_id, access_token, email = get_id_token_and_email(request)

    sqlalchemy_session = sql_session_init(email, access_token)

    files = request.files
    for i in files:
        file = files[i]
        print(file)
        print(i)
        if allowed_file(file.filename):
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], i)
            file.save(filepath)
            url = upload_image_to_bucket(filepath)
            insert_stmt = insert(File).values(title=file.filename, owner_email=email, storage_url=url)\
                .returning(File.file_id)
            result = sqlalchemy_session.execute(insert_stmt)
            file_id = result.first().file_id
            print(file_id)
            file_to_embedding(filepath, sqlalchemy_session, email, file_id)
        else:
            return "File must be either be a .pdf or .txt file", 415
    sqlalchemy_session.commit()
    return "Successfully uploaded file", 201


@app.route('/get-user-info', methods=['GET'])
@require_auth(None)
def get_user_info():
    user_id, access_token, email = get_id_token_and_email(request)

    sqlalchemy_session = sql_session_init(email, access_token)

    profile = sqlalchemy_session.execute(select(UserProfile).where(UserProfile.email == email)).scalar_one()

    return serialize_user_profile(profile)


@app.route('/generate-qna', methods=['GET'])
@require_auth(None)
def generate_qna():

    user_id, access_token, email = get_id_token_and_email(request)

    sqlalchemy_session = sql_session_init(email, access_token)

    query = request.args["query"]
    query = query.replace("_", " ")
    print(query)
    print(request.args["file_ids"])
    file_ids = request.args["file_ids"][1:len(request.args["file_ids"])-1].split(", ")
    file_ids = [int(i) for i in file_ids]
    print(file_ids)
    conversation_id = int(request.args["conversation_id"])

    answer = get_answer_from_chunks(query, sqlalchemy_session, email, file_ids, conversation_id)
    return answer


@app.route('/get-user-files', methods=['GET'])
@require_auth(None)
def get_files():
    access_token = request.headers['authorization'][7:]
    access_token_payload = jwt.decode(access_token, options={"verify_signature": False})
    email = access_token_payload["gpt-doc-reader/email"]

    engine = create_engine(f"postgresql+psycopg://{email}:" +
                           f"{access_token}@/gpt_doc_reader_postgres?host=localhost:5433")
    sqlalchemy_session = Session(engine)

    file_get_stmt = select(File).where(File.owner_email == email)
    user_files = sqlalchemy_session.execute(file_get_stmt).all()
    return jsonify([i[0].storage_url for i in user_files])











    
