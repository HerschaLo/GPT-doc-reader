import firebase_admin
from firebase_admin import credentials, storage
from datetime import MAXYEAR
cred = credentials.Certificate('private_key.json')

app = firebase_admin.initialize_app(cred, {"storageBucket": "gpt-doc-reader.appspot.com"})

image_bucket = storage.bucket()


def upload_image_to_bucket(filepath):
    blob = image_bucket.blob(filepath)
    blob.upload_from_filename(filepath)
    blob_url = blob.generate_signed_url(MAXYEAR)
    return blob_url
