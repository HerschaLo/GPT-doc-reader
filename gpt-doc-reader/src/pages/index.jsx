import '../styles/index.css'

const Index = () => {

return (
    <div className="bg-slate-900 w-screen h-screen grid justify-items-center">
        <h1 className="text-5xl">GPT doc reader</h1>
        <div className="w-2/3">
            <p>We leverage the power of OpenAI&apos;s GPT-4 for processing your documents like resumes and textbooks to give you personalized AI-powered assisstance 
                based on the information in them. From giving a quick summary of the key points for a university textbook chapter to automating cover letter writing for a job based on your resume, we&apos;ll cover all your document needs!
            </p>
        </div>
    </div>
)
}

export default Index
