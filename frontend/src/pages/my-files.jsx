import { useEffect, useState, useContext} from "react";
import { TokenContext } from "../components/layout";
const Profile = () => {
    const [currentFiles, setFiles] = useState(null)
    const [filesToUpload, setFilesToUpload] = useState(null)
    const [txt, setTxt] = useState(null)
    const accessToken = useContext(TokenContext)

    const handleFileSelection = (e)=>{
        let fieldFiles = e.target.files
        setFilesToUpload(fieldFiles)
        console.log(fieldFiles)
    }

    const handleFileUpload = async () =>{
        let fieldFiles = filesToUpload
        let fileFormData = new FormData()
        console.log(fieldFiles)
        for(let i=0; i<fieldFiles.length; i++){
            let file = fieldFiles[i]
            fileFormData.append(file.name, file)
        }

        fetch("http://127.0.0.1:5000/upload-files",{
            method:"POST",
            headers:{
                "Authorization":`Bearer ${accessToken}`
            },
            body:fileFormData
        }).then(async (res)=>{
            let responseText = await res.text()
            console.log(responseText)
        })
    }
    
    useEffect(() => {

        const getUserFiles = async ()=> {
            if(currentFiles === null){
                console.log(accessToken)
                const fetchedFileData = await (await fetch("http://127.0.0.1:5000/get-user-files",{
                    headers:{
                        "Authorization":`Bearer ${accessToken}`
                    }
                })).json()
                setFiles(fetchedFileData)
                console.log(fetchedFileData)
            }
        }

        getUserFiles()
    }, [accessToken, currentFiles])

    const handleQuerySubmit = async (e) =>{
        fetch(`http://127.0.0.1:5000/generate-qna?query=${txt}&file_ids=[1]&conversation_id=1`,{
            headers:{
                "Authorization":`Bearer ${accessToken}`
            },
        }).then(async (res)=>{
            let responseText = await res.text()
            console.log(responseText)
        })
    }

    console.log(currentFiles)
    console.log(filesToUpload)
    return (
        <div>
            <input type="file" multiple accept=".pdf" onChange={(e)=>{handleFileSelection(e)}} />
            <button onClick={()=>{handleFileUpload()}}>Upload files</button>
            <input type="text" onChange={(e)=>{setTxt(e.target.value)}} />
            <button onClick={()=>{handleQuerySubmit()}}>submit query</button>
        </div>
    )
}

export default Profile
