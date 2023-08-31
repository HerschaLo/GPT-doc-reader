import { useEffect, useState, useContext } from "react";
import { TokenContext } from "../components/layout";
const Profile = () => {
    const [profileData, setProfileData] = useState(null)
    const accessToken = useContext(TokenContext)

    useEffect(() => {
        const getProfileData = async ()=> {
            console.log(accessToken)
            const fetchedProfileData = await (await fetch("http://127.0.0.1:5000/get-user-info",{
                headers:{
                    "Authorization":`Bearer ${accessToken}`
                }
            })).json()
            console.log(fetchedProfileData)
            setProfileData(fetchedProfileData)
        }

        getProfileData()

    }, [accessToken])

    console.log(profileData)
    return (
        <div>
            
        </div>
    )
}

export default Profile
