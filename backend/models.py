from sqlalchemy.orm import DeclarativeBase, mapped_column
from sqlalchemy import Text, Boolean, BigInteger, ForeignKey, UUID, Column
from pgvector.sqlalchemy import Vector


class Base(DeclarativeBase):
    pass


class UserProfile(Base):
    __tablename__ = "user_profiles"
    user_id = mapped_column(Text, primary_key=True)
    email = mapped_column(Text, unique=True, nullable=False)
    verified = mapped_column(Boolean)


class File(Base):
    __tablename__ = "files"
    file_id = mapped_column(BigInteger, primary_key=True)
    title = mapped_column(Text, nullable=False)
    storage_url = mapped_column(Text, nullable=False)
    owner_email = mapped_column(ForeignKey("user_profiles.email"))


class FileEmbedding(Base):
    __tablename__ = "file_embeddings"
    embedding = mapped_column(Vector(1536), nullable=False)
    embedding_id = mapped_column(UUID, nullable=False)
    embedding_owner = mapped_column(ForeignKey("user_profiles.email"))
    source_file = mapped_column(ForeignKey("files.file_id"))
    embedding_text = mapped_column(Text, nullable=False)
    # Necessary b/c table doesn't have pk in postgres but sqlalchemy requires a pk
    fake_column = Column(primary_key=True)


def create_user_embedding_table(email):
    class UserFileEmbedding(Base):
        __tablename__ = email+"_file_embeddings"
        embedding = mapped_column(Vector(1536), nullable=False)
        embedding_id = mapped_column(UUID, nullable=False)
        embedding_owner = mapped_column(ForeignKey("user_profiles.email"))
        source_file = mapped_column(ForeignKey("files.file_id"))
        embedding_text = mapped_column(Text, nullable=False)
        # Necessary b/c table doesn't have pk in postgres but sqlalchemy requires a pk
        fake_column = Column(primary_key=True)

    return UserFileEmbedding


