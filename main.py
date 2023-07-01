from dotenv import load_dotenv, find_dotenv
from langchain.llms import OpenAI
load_dotenv(find_dotenv())
llm = OpenAI(model_name="text-davinci-003")
print(llm("explain how humans fart"))


