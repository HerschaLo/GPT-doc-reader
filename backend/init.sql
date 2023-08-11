DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS files;
DROP TABLE IF EXISTS conversations;
DROP TABLE IF EXISTS conversation_and_users_junction;
DROP TABLE IF EXISTS human_messages;
DROP TABLE IF EXISTS bot_messages;
DROP TABLE IF EXISTS user_sessions;

CREATE EXTENSION vector;

CREATE TABLE user_profiles(
    user_id text PRIMARY KEY,
    email text NOT NULL UNIQUE,
    verified boolean NOT NULL
);

CREATE TABLE files (
    file_id bigserial PRIMARY KEY,
    title text NOT NULL,
    storage_url text NOT NULL UNIQUE,
    owner_email text,
    CONSTRAINT file_owner
        FOREIGN KEY(owner_email) 
	        REFERENCES user_profiles(email)
            ON DELETE CASCADE
);

CREATE TABLE conversations (
    conversation_id bigserial PRIMARY KEY,
    conversation_owner text,
    CONSTRAINT conversation_owner
        FOREIGN KEY(conversation_owner) 
	        REFERENCES user_profiles(email)
            ON DELETE CASCADE
);

CREATE TABLE human_messages (
    message_content text,
    message_timestamp timestamptz,
    message_sender text,
    message_id bigserial PRIMARY KEY,
    source_conversation bigint,
    CONSTRAINT message_sender_fk
        FOREIGN KEY(message_sender) 
	        REFERENCES user_profiles(email)
            ON DELETE CASCADE,
    CONSTRAINT conversation_fk
        FOREIGN KEY(source_conversation)
            REFERENCES conversations
            ON DELETE CASCADE
);

CREATE TABLE bot_messages (
    message_content text,
    message_timestamp timestamptz,
    message_id bigserial PRIMARY KEY,
    source_conversation bigint,
    message_owner text,
    CONSTRAINT conversation_fk
        FOREIGN KEY(source_conversation)
            REFERENCES conversations
            ON DELETE CASCADE,
    CONSTRAINT message_owner_fk
        FOREIGN KEY(message_owner) 
            REFERENCES user_profiles(email)
            ON DELETE CASCADE
);

CREATE TABLE embeddings (
    embedding_id bigserial PRIMARY KEY,
    embedding vector(3),
    source_file bigint,
    CONSTRAINT source_file_fk
        FOREIGN KEY(source_file)
            REFERENCES files
            ON DELETE CASCADE
);

CREATE TABLE files_access_junction (
    user_email text,
    file_id bigint,
    PRIMARY KEY(user_email, file_id),
    CONSTRAINT file_id_fk
        FOREIGN KEY(file_id)
            REFERENCES files
            ON DELETE CASCADE,
    CONSTRAINT user_email_fk
        FOREIGN KEY(user_email) 
            REFERENCES user_profiles(email)
            ON DELETE CASCADE

);



CREATE ROLE temp_access_user;

ALTER TABLE files ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

ALTER TABLE human_messages ENABLE ROW LEVEL SECURITY;

ALTER TABLE bot_messages ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE 
    session_creator_password text := current_setting('session_creator.password');
BEGIN
    EXECUTE format(
        'CREATE ROLE session_creator WITH
            LOGIN PASSWORD %L'
         , session_creator_password
    );
END $$;

GRANT INSERT ON user_profiles TO session_creator;

BEGIN;
    CREATE OR REPLACE FUNCTION create_temp_access_user(auth0_user_id text, access_token text) RETURNS void AS $$
        DECLARE
            user_email text;
            expiration_date timestamptz := current_timestamp + interval '1 day';
        BEGIN
            SELECT email INTO user_email FROM user_profiles WHERE user_profiles.user_id = auth0_user_id LIMIT 1;
            IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_user WHERE pg_user.usename = user_email) THEN
                EXECUTE format(
                    'CREATE USER %I WITH LOGIN PASSWORD %L VALID UNTIL %L;
                    GRANT temp_access_user TO %I', 
                    user_email,
                    access_token,
                    expiration_date,
                    user_email
                );
            ELSE
                EXECUTE format(
                    'ALTER USER %I WITH PASSWORD %L VALID UNTIL %L;',
                    user_email,
                    access_token,
                    expiration_date
                );
            END IF;
        END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;
    REVOKE ALL ON FUNCTION create_temp_access_user(auth0_user_id text, access_token text) FROM PUBLIC;
    GRANT EXECUTE ON FUNCTION create_temp_access_user(auth0_user_id text, access_token text) TO session_creator;
COMMIT;

CREATE POLICY file_owner_access ON files TO temp_access_user
    USING (owner_email = current_user);

CREATE POLICY file_general_access ON files FOR SELECT TO temp_access_user
    USING (
        EXISTS(
            SELECT 1 FROM files_access_junction WHERE files_access_junction.file_id = file_id AND files_access_junction.user_email = current_user
        )
    );

CREATE POLICY embedding_owner_access ON embeddings to temp_access_user
    USING (
        EXISTS(
            SELECT 1 FROM files WHERE files.owner_email = current_user AND files.file_id = source_file
        )
    );

CREATE POLICY profile_info_access ON user_profiles FOR SELECT TO temp_access_user
    USING (email = current_user);

CREATE POLICY profile_creation ON user_profiles FOR INSERT TO session_creator
    WITH CHECK (true);

CREATE POLICY conversation_access ON conversations TO temp_access_user
    USING (conversation_owner = current_user);

CREATE POLICY human_message_access ON human_messages TO temp_access_user
    USING (message_sender = current_user);

CREATE POLICY bot_message_access ON bot_messages TO temp_access_user
    USING (message_owner = current_user);

CREATE POLICY file_junction_owner_access ON files_access_junction TO temp_access_user USING
    (current_user = user_email)



