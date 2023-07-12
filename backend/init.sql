DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS files;
DROP TABLE IF EXISTS conversations;
DROP TABLE IF EXISTS conversation_and_users_junction;
DROP TABLE IF EXISTS human_messages;
DROP TABLE IF EXISTS bot_messages;

CREATE TABLE user_profiles(
    username text PRIMARY KEY,
    email text NOT NULL UNIQUE,
    verified boolean NOT NULL
);

CREATE TABLE files (
    file_id SERIAL PRIMARY KEY,
    title text NOT NULL,
    storage_url text NOT NULL UNIQUE,
    owner_username text,
    CONSTRAINT file_owner
        FOREIGN KEY(owner_username) 
	        REFERENCES user_profiles
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
	        REFERENCES user_profiles
            ON DELETE CASCADE
);

CREATE TABLE conversation_and_users_junction(
    conversation_id SERIAL,
    username text,
    CONSTRAINT user_fk
        FOREIGN KEY(username) 
            REFERENCES user_profiles
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
	        REFERENCES user_profiles
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


CREATE ROLE users;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA "public" TO users;

ALTER TABLE files ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

ALTER TABLE conversation_and_users_junction ENABLE ROW LEVEL SECURITY;

ALTER TABLE human_messages ENABLE ROW LEVEL SECURITY;

ALTER TABLE bot_messages ENABLE ROW LEVEL SECURITY;


CREATE POLICY file_access ON files TO users
    USING (owner_username = current_user);

CREATE POLICY profile_info_access ON user_profiles FOR SELECT TO users
    USING (username = current_user);

CREATE POLICY conversation_access ON conversations 
    FOR SELECT 
    TO users
    USING (
        EXISTS (
            SELECT 1 FROM conversation_and_users_junction
            WHERE conversation_and_users_junction.username = current_user
            AND conversation_and_users_junction.conversation_id = conversation_id
        )
    );

CREATE POLICY conversation_owner_access ON conversations TO users
    USING (conversation_owner = current_user);

CREATE POLICY human_message_access ON human_messages
    FOR SELECT 
    TO users
    USING (
        EXISTS (
            SELECT 1 FROM conversation_and_users_junction
            WHERE conversation_and_users_junction.username = current_user
            AND conversation_and_users_junction.conversation_id = source_conversation
        )
    );

CREATE POLICY human_message_owner_access ON human_messages TO users
    USING (message_sender = current_user);

CREATE POLICY bot_message_access ON bot_messages
    FOR SELECT 
    TO users
    USING (
        EXISTS (
            SELECT 1 FROM conversation_and_users_junction
            WHERE conversation_and_users_junction.username = current_user
            AND conversation_and_users_junction.conversation_id = source_conversation
        )
    );

CREATE POLICY bot_message_owner_access ON bot_messages TO users
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.conversation_id = source_conversation
            AND conversations.conversation_owner = current_user
        )
    );
