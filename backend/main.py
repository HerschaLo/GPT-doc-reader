from dotenv import load_dotenv, find_dotenv
from langchain.llms import OpenAI
from langchain.text_splitter import RecursiveCharacterTextSplitter
from PyPDF2 import PdfReader
from langchain.embeddings import OpenAIEmbeddings
load_dotenv(find_dotenv())


reader = PdfReader("test.pdf")
number_of_pages = len(reader.pages)
page = reader.pages[0]
text = page.extract_text()

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size = 100,
    chunk_overlap = 0,
)
res = text_splitter.create_documents([text])

embeddings = OpenAIEmbeddings(model_name='ada')
query_result = embeddings.embed_query(res[0].page_content)


