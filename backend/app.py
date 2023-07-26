import os
from flask import Flask, request, session
from authlib.integrations.flask_oauth2 import ResourceProtector
from validator import Auth0JWTBearerTokenValidator
from sqlalchemy import create_engine
from dotenv import load_dotenv, find_dotenv
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, Session
from sqlalchemy import Text, ForeignKeyConstraint, select, insert
import jwt
load_dotenv(find_dotenv())


class Base(DeclarativeBase):
    pass


class UserSession(Base):
    __tablename__ = "user_sessions"
    __table_args__ = (
        ForeignKeyConstraint(["user_id"], ["user_profiles.user_id"])
    )
    user_id = mapped_column(Text, primary_key=True)
    access_token = mapped_column(Text, unique=True)


require_auth = ResourceProtector()
validator = Auth0JWTBearerTokenValidator(
    "dev-4et1s8fqfxunww8q.us.auth0.com",
    "gpt-doc-reader-api"
)
require_auth.register_token_validator(validator)
app = Flask(__name__)
app.secret_key = os.environ.get('SESSION_SECRET_KEY')

@app.route('/login', method="POST")
@require_auth(None)
def basic_user_auth():
    engine = create_engine(f"postgresql+psycopg://{os.environ.get('SESSION_CREATOR_ROLE')}:" +
                           f"{os.environ.get('SESSION_CREATOR_PASSWORD')}@/gpt_doc_reader_postgres?host=localhost:5433")
    sqlalchemy_session = Session(engine)

    access_token = request.headers['authorization'][7:]
    access_token_payload = jwt.decode(access_token, options={"verify_signature": False})
    user_id = access_token_payload["sub"]
    email = request.data

    user_session_row = sqlalchemy_session.execute(select(UserSession).where(UserSession.user_id == user_id)).first()
    if user_session_row is not None:
        user_session_row.access_token = access_token
        sqlalchemy_session.commit()
    else:
        sqlalchemy_session.execute(insert(UserSession).values(user_id=user_id, access_token=access_token))
    session['email'] = email






    
