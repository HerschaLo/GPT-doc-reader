DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS files;

CREATE TABLE user_profiles(
    username text NOT NULL UNIQUE,
    email text PRIMARY KEY,
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
);
