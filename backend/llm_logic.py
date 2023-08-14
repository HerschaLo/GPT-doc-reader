import flask 
from waitress import serve
from flask import request, jsonify, session
from dotenv import load_dotenv, find_dotenv
from langchain.llms import OpenAI
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Pinecone
from langchain.text_splitter import RecursiveCharacterTextSplitter
import os
import pinecone
from PyPDF2 import PdfReader
from langchain.chains.question_answering import load_qa_chain
from langchain import PromptTemplate
from langchain.memory import ConversationBufferMemory

load_dotenv(find_dotenv())
pinecone.init(
    api_key=os.getenv("PINECONE_API_KEY"),
    environment = os.getenv("PINECONE_ENV")
)

prompt_template = "This is some information on a topic: {context}. Generate a question and answer pair related to the topic in this format: \n Question: \n Answer: "


prompt = PromptTemplate(

    template=prompt_template,
    input_variables=["context"]
)
chain = load_qa_chain(OpenAI(), chain_type="stuff", prompt=prompt)

embeddings = OpenAIEmbeddings()

index_name = "testing"
search = Pinecone.from_existing_index(index_name, embeddings)



app = flask.Flask(__name__)
app.config["DEBUG"] = True
app.secret_key = b'_5#y2L"F4Q8z\n\xec]/'


@app.route('/', methods=['GET'])
def home():
    return '''<h1>home page</h1>
'''

@app.route('/generateqna', methods=['GET'])
def returnQuery():
    question = request.args["query"]
    question = question.replace("_", " ")
    similar_chunks = search.similarity_search(question)
    #INSERT FUNCTION HERE
    answer = chain.run({"input_documents": similar_chunks})
    answer = answer.replace("\n", "")
    answer = jsonify(answer)
    #for cors
    answer.headers.add("Access-Control-Allow-Origin", "*")
    return answer

#change this part idk how to accept pdf from flask
@app.route('/uploadembeddings', methods=['GET'])
def addEmbeddings():
    totaltext = ""
    
    #reads the pdf, takes text

    reader = PdfReader("childhood_diseases.pdf")
    for page in reader.pages:
        totaltext = totaltext + " " + page.extract_text()

    #start generating embedding
    text_splitter = RecursiveCharacterTextSplitter(
    chunk_size = 600,
    chunk_overlap = 100,
    )
    res = text_splitter.create_documents([totaltext])

    #put the embedding in pinecone
    Pinecone.from_documents(res, embeddings, index_name=index_name)
    return


serve(app, host='0.0.0.0', port=8000)