INSERT INTO user_profiles(username, email, verified)
VALUES 
    (dummy_user_1, fake_email_1@gmail.com, false),
    (dummy_user_2, fake_email_2@gmail.com, false),
    (dummy_user_3, fake_email_3@gmail.com, false);

CREATE USER dummy_user_1 with PASSWORD 'fake_password1.';
GRANT users to dummy_user_1;
CREATE USER dummy_user_2 with PASSWORD 'fake_password2.';
GRANT users to dummy_user_2;
CREATE USER dummy_user_3 with PASSWORD 'fake_password3.';
GRANT users to dummy_user_3;
