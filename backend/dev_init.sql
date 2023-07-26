INSERT INTO user_profiles(user_id, email, verified)
VALUES 
    ('erg43645h', 'fake_email_1@gmail.com', false),
    ('frg43645h', 'fake_email_2@gmail.com', false),
    ('grg43645h', 'fake_email_3@gmail.com', false);

INSERT INTO user_sessions(access_token, user_id)
VALUES 
    ('fake_access_token', 'grg43645h');

DELETE FROM user_sessions WHERE user_id ='grg43645h';
