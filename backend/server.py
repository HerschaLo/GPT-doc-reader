import os
from flask import Flask, request
from authlib.integrations.flask_oauth2 import ResourceProtector
from validator import Auth0JWTBearerTokenValidator, allowed_file
from sqlalchemy import create_engine
from dotenv import load_dotenv, find_dotenv
from sqlalchemy.orm import DeclarativeBase, mapped_column, Session
from sqlalchemy import Text, Boolean, select
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import insert
import jwt
from flask_cors import CORS
from serialize import serialize_user_profile
load_dotenv(find_dotenv())


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
UPLOAD_FOLDER = os.path.abspath('uploads')
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
CORS(app)




@app.route('/login', methods=['POST'])
@require_auth(None)
def login():
    session_creator_engine = create_engine(f"postgresql+psycopg://{os.environ.get('SESSION_CREATOR_ROLE')}:" +
                           f"{os.environ.get('SESSION_CREATOR_PASSWORD')}@/gpt_doc_reader_postgres?host=localhost:5433")
    sqlalchemy_session = Session(session_creator_engine)

    access_token = request.headers['authorization'][7:]
    access_token_payload = jwt.decode(access_token, options={"verify_signature": False})
    user_id = access_token_payload["sub"]
    email = access_token_payload["gpt-doc-reader/email"]

    insert_stmt = insert(UserProfile).values(email=email, user_id=user_id, verified=False)
    insert_stmt = insert_stmt.on_conflict_do_nothing()
    sqlalchemy_session.execute(insert_stmt)

    create_temp_access_user = func.create_temp_access_user(user_id, access_token)
    sqlalchemy_session.execute(create_temp_access_user)
    sqlalchemy_session.commit()

    return "", 200


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
        if allowed_file(file.filename):

            return "", 200
        else:
            return "File must be either be a .pdf or .txt file", 415


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

    return serialize_user_profile(profile)


@app.route('/generate-qna', methods=['GET'])
@require_auth(None)
def returnQuery():
    question = request.args["query"]
    question = question.replace("_", " ")
    similar_chunks = search.similarity_search(question)
    # INSERT FUNCTION HERE
    answer = chain.run({"input_documents": similar_chunks})
    answer = answer.replace("\n", "")
    answer = jsonify(answer)
    # for cors
    answer.headers.add("Access-Control-Allow-Origin", "*")
    return answer


# change this part idk how to accept pdf from flask
@app.route('/upload-embeddings', methods=['POST'])
@require_auth(None)
def add_embeddings():












    
