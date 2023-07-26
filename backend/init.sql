DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS files;
DROP TABLE IF EXISTS conversations;
DROP TABLE IF EXISTS conversation_and_users_junction;
DROP TABLE IF EXISTS human_messages;
DROP TABLE IF EXISTS bot_messages;
DROP TABLE IF EXISTS user_sessions;

CREATE TABLE user_profiles(
    user_id text PRIMARY KEY,
    email text NOT NULL UNIQUE,
    verified boolean NOT NULL
);

CREATE TABLE files (
    file_id SERIAL PRIMARY KEY,
    title text NOT NULL,
    storage_url text NOT NULL UNIQUE,
    owner_email text,
    CONSTRAINT file_owner
        FOREIGN KEY(owner_email) 
	        REFERENCES user_profiles(email)
            ON DELETE CASCADE
);

CREATE TYPE message_base_info AS (
    message_content text,
    message_timestamp timestamptz
);

CREATE TABLE conversations (
    conversation_id SERIAL PRIMARY KEY,
    conversation_owner text,
    CONSTRAINT conversation_owner
        FOREIGN KEY(conversation_owner) 
	        REFERENCES user_profiles(email)
            ON DELETE CASCADE
);

CREATE TABLE conversation_and_users_junction(
    conversation_id SERIAL,
    user_email text,
    CONSTRAINT user_fk
        FOREIGN KEY(user_email) 
            REFERENCES user_profiles(email)
            ON DELETE CASCADE,
    CONSTRAINT conversation_fk
        FOREIGN KEY(conversation_id)
            REFERENCES conversations
            ON DELETE CASCADE
);

CREATE TABLE human_messages (
    base_info message_base_info,
    message_sender text,
    message_id SERIAL PRIMARY KEY,
    source_conversation SERIAL,
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
    base_info message_base_info,
    message_id SERIAL PRIMARY KEY,
    source_conversation SERIAL,
    CONSTRAINT conversation_fk
        FOREIGN KEY(source_conversation)
            REFERENCES conversations
            ON DELETE CASCADE
);

CREATE TABLE user_sessions (
    access_token text UNIQUE,
    user_id text PRIMARY KEY,
    CONSTRAINT user_id_fk
        FOREIGN KEY(user_id)
            REFERENCES user_profiles
            ON DELETE CASCADE
);

CREATE ROLE temp_access_user;

ALTER TABLE files ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

ALTER TABLE conversation_and_users_junction ENABLE ROW LEVEL SECURITY;

ALTER TABLE human_messages ENABLE ROW LEVEL SECURITY;

ALTER TABLE bot_messages ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

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

GRANT INSERT, UPDATE ON user_sessions TO session_creator;

BEGIN;
    CREATE OR REPLACE FUNCTION create_temp_access_user() RETURNS TRIGGER AS $$
        DECLARE
            user_email text;
            expiration_date timestamptz := current_timestamp + interval '1 day';
        BEGIN
            SELECT email INTO user_email FROM user_profiles WHERE user_profiles.user_id = NEW.user_id LIMIT 1;
            IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_user WHERE pg_user.usename = user_email) THEN
                EXECUTE format(
                    'CREATE USER %I WITH LOGIN PASSWORD %L VALID UNTIL %L;
                    GRANT temp_access_user TO %I', 
                    user_email,
                    NEW.access_token,
                    expiration_date,
                    user_email
                );
            ELSE
                EXECUTE format(
                    'ALTER USER %I WITH PASSWORD %L VALID UNTIL %L;',
                    user_email,
                    NEW.access_token,
                    expiration_date
                );
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;
    REVOKE ALL ON FUNCTION create_temp_access_user() FROM PUBLIC;
    GRANT EXECUTE ON FUNCTION create_temp_access_user() TO session_creator;
COMMIT;

CREATE OR REPLACE TRIGGER create_login_on_user_auth AFTER INSERT OR UPDATE ON user_sessions 
FOR EACH ROW 
EXECUTE FUNCTION create_temp_access_user();

CREATE POLICY file_access ON files TO temp_access_user
    USING (owner_email = current_user);

CREATE POLICY profile_info_access ON user_profiles FOR SELECT TO temp_access_user
    USING (email = current_user);

CREATE POLICY conversation_access ON conversations 
    FOR SELECT 
    TO temp_access_user
    USING (
        EXISTS (
            SELECT 1 FROM conversation_and_users_junction
            WHERE conversation_and_users_junction.user_email = current_user
            AND conversation_and_users_junction.conversation_id = conversation_id
        )
    );

CREATE POLICY conversation_owner_access ON conversations TO temp_access_user
    USING (conversation_owner = current_user);

CREATE POLICY human_message_access ON human_messages
    FOR SELECT 
    TO temp_access_user
    USING (
        EXISTS (
            SELECT 1 FROM conversation_and_users_junction
            WHERE conversation_and_users_junction.user_email = current_user
            AND conversation_and_users_junction.conversation_id = source_conversation
        )
    );

CREATE POLICY human_message_owner_access ON human_messages TO temp_access_user
    USING (message_sender = current_user);

CREATE POLICY bot_message_access ON bot_messages
    FOR SELECT 
    TO temp_access_user
    USING (
        EXISTS (
            SELECT 1 FROM conversation_and_users_junction
            WHERE conversation_and_users_junction.user_email = current_user
            AND conversation_and_users_junction.conversation_id = source_conversation
        )
    );

CREATE POLICY bot_message_owner_access ON bot_messages TO temp_access_user
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.conversation_id = source_conversation
            AND conversations.conversation_owner = current_user
        )
    );

CREATE POLICY session_creation_insert ON user_sessions FOR INSERT TO session_creator
    WITH CHECK (true);

CREATE POLICY session_creation_update ON user_sessions FOR UPDATE TO session_creator
    WITH CHECK (true);



