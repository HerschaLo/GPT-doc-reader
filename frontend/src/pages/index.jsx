import '../styles/index.scss'
import clipartRobo from "../assets/clipartRobo.PNG"
import magnifyText from "../assets/magnifyText.PNG"
import { Link } from "react-router-dom"
const Index = () => {

    return (
        <>
            <h1 className="text-7xl">GPT doc reader</h1>
            <img src={clipartRobo} />
            <div className="w-2/3 mb-16">
                <p className="text-xl">We leverage the power of OpenAI&apos;s GPT-4 for processing your documents like resumes and textbooks to give you personalized AI-powered assisstance
                    based on the information in them.
                </p>
            </div>
            <Link to="/auth" className="bg-slate-700 px-6 py-4 mb-16 flex items-center justify-center text-4xl rounded-lg transition duration-300 hover:bg-slate-200 hover:text-black">Try it now!</Link>
            <div className="grid w-2/3">
                <h2 className="text-5xl">Quick Insight</h2>
                <img src={magnifyText} className="justify-self-center" />
                <p className="justify-self-center text-lg">Generate a quick summary of the key information in a document. Perfect for skimming through the main points of a chapter in your textbook, or
                    getting a convenient overview of a lengthy article you&apos;re reading for a research project.
                </p>
            </div>
        </>
    )
}

export default Index
