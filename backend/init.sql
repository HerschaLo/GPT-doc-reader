DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS files;
DROP TABLE IF EXISTS conversations;
DROP TABLE IF EXISTS conversation_and_users_junction;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS user_sessions;

CREATE EXTENSION vector;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE user_profiles (
    user_id text PRIMARY KEY,
    email text NOT NULL UNIQUE,
    verified boolean NOT NULL
);

CREATE TABLE bots (
    bot_owner text NOT NULL,
    bot_id bigserial PRIMARY KEY,
    bot_name text NOT NULL,
    CONSTRAINT bot_owner_fk
        FOREIGN KEY(bot_owner) 
                REFERENCES user_profiles(email)
                ON DELETE CASCADE
);

CREATE TABLE files (
    file_id bigserial PRIMARY KEY,
    title text NOT NULL,
    storage_url text NOT NULL UNIQUE,
    owner_email text NOT NULL,
    CONSTRAINT file_owner
        FOREIGN KEY(owner_email) 
	        REFERENCES user_profiles(email)
            ON DELETE CASCADE
);

CREATE TABLE conversations (
    conversation_id bigserial PRIMARY KEY,
    conversation_owner text NOT NULL,
    bot bigint NOT NULL,
    CONSTRAINT conversation_owner_fk
        FOREIGN KEY(conversation_owner) 
	        REFERENCES user_profiles(email)
            ON DELETE CASCADE,
    CONSTRAINT bot_fk
        FOREIGN KEY(bot) 
	        REFERENCES bots
            ON DELETE CASCADE
);

CREATE TABLE messages (
    message_content text NOT NULL,
    message_timestamp timestamptz NOT NULL,
    message_id uuid DEFAULT uuid_generate_v4 () NOT NULL,
    source_conversation bigint NOT NULL,
    conversation_bot bigint NOT NULL,
    is_bot_message boolean NOT NULL,
    message_owner text NOT NULL,
    CONSTRAINT message_owner_fk
        FOREIGN KEY(message_owner) 
	        REFERENCES user_profiles(email)
            ON DELETE CASCADE,
    CONSTRAINT conversation_fk
        FOREIGN KEY(source_conversation)
            REFERENCES conversations
            ON DELETE CASCADE,
    CONSTRAINT conversation_bot_fk
        FOREIGN KEY(conversation_bot)
            REFERENCES bots
            ON DELETE CASCADE
) PARTITION BY LIST (message_owner);

CREATE TABLE embeddings_template_table (
    embedding vector(1536) NOT NULL,
    embedding_id uuid DEFAULT uuid_generate_v4 () NOT NULL,
    embedding_owner text NOT NULL,
    embedding_text text NOT NULL,
    CONSTRAINT embedding_owner_fk
        FOREIGN KEY(embedding_owner) 
            REFERENCES user_profiles(email)
            ON DELETE CASCADE
);

CREATE TABLE message_embeddings (LIKE embeddings_template_table) PARTITION BY LIST (embedding_owner);
ALTER TABLE message_embeddings ADD COLUMN source_message uuid;


CREATE TABLE file_embeddings (LIKE embeddings_template_table) PARTITION BY LIST (embedding_owner);
ALTER TABLE file_embeddings ADD COLUMN source_file bigint;
ALTER TABLE file_embeddings ADD CONSTRAINT source_file_fk
FOREIGN KEY(source_file)
    REFERENCES files(file_id)
    ON DELETE CASCADE;
CREATE INDEX source_file_index ON file_embeddings USING HASH (source_file);

CREATE TABLE files_access_junction (
    bot_id bigint NOT NULL,
    file_id bigint NOT NULL,
    PRIMARY KEY(bot_id, file_id),
    CONSTRAINT file_id_fk
        FOREIGN KEY(file_id)
            REFERENCES files(file_id)
            ON DELETE CASCADE,
    CONSTRAINT bot_id_fk
        FOREIGN KEY(bot_id) 
            REFERENCES bots
            ON DELETE CASCADE
);

CREATE TABLE bots_access_junction (
    user_email text NOT NULL,
    bot_id bigint NOT NULL,
    PRIMARY KEY(bot_id, user_email),
    CONSTRAINT user_email_fk
        FOREIGN KEY(user_email)
            REFERENCES user_profiles(email)
            ON DELETE CASCADE,
    CONSTRAINT bot_id_fk
        FOREIGN KEY(bot_id) 
            REFERENCES bots
            ON DELETE CASCADE
);



CREATE ROLE temp_access_user;

GRANT INSERT, UPDATE, SELECT, DELETE
ON ALL TABLES IN SCHEMA public 
TO temp_access_user;

GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO temp_access_user;

ALTER TABLE files ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

ALTER TABLE files_access_junction ENABLE ROW LEVEL SECURITY;

ALTER TABLE bots_access_junction ENABLE ROW LEVEL SECURITY;

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
			user_message_embedding_partition text;
			user_file_embedding_partition text;
			user_message_partition text;						
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
				user_message_embedding_partition := user_email || '_message_embeddings';
				user_file_embedding_partition := user_email || '_file_embeddings';
				user_message_partition := user_email || '_messages';

                EXECUTE format(
                    'CREATE TABLE %1$I PARTITION OF messages FOR VALUES IN (%2$L);
                    ALTER TABLE %1$I ADD PRIMARY KEY (message_id);
                    ', 
                    user_message_partition,
                    user_email
                );

                EXECUTE format(
                    'CREATE TABLE %1$I PARTITION OF message_embeddings FOR VALUES IN (%2$L);
                    ALTER TABLE %1$I ADD CONSTRAINT source_message_fk
                    FOREIGN KEY(source_message)
                        REFERENCES %3$I(message_id)
                        ON DELETE CASCADE;
                    ', 
                    user_message_embedding_partition,
                    user_email,
                    user_message_partition
                );

                EXECUTE format(
                    'CREATE TABLE %1$I PARTITION OF file_embeddings FOR VALUES IN (%2$L);
                        GRANT INSERT, UPDATE, SELECT, DELETE
                        ON %1$I TO temp_access_user;
                    ', 
                    user_file_embedding_partition,
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

CREATE OR REPLACE FUNCTION file_general_access_check() RETURNS boolean AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM bots_access_junction, 
        files_access_junction WHERE bots_access_junction.user_email = current_user AND 
        files_access_junction.file_id = file_id AND bots_access_junction.bot_id = files_access_junction.bot_id
    );
END
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE POLICY file_owner_access ON files TO temp_access_user
    USING (owner_email = current_user);

CREATE POLICY file_general_access ON files FOR SELECT TO temp_access_user
    USING (
        file_general_access_check()
    );

CREATE POLICY embedding_owner_access ON file_embeddings TO temp_access_user
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

CREATE POLICY message_access ON messages TO temp_access_user
    USING (message_owner = current_user);

CREATE POLICY file_junction_owner_access ON files_access_junction TO temp_access_user 
    USING(
        EXISTS(
            SELECT 1 FROM files WHERE files.file_id = file_id and files.owner_email = current_user
        )
    );

CREATE POLICY bots_junction_owner_access ON bots_access_junction TO temp_access_user USING
    (current_user = user_email)



