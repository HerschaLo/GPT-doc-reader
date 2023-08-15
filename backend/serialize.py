def serialize_user_profile(user_profile):
    return {"email": user_profile.email, "user_id": user_profile.user_id, "verified": user_profile.verified}