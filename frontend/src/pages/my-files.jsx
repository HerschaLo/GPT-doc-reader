import { useAuth0 } from "@auth0/auth0-react"
import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
const Profile = () => {
    const { isLoading, isAuthenticated, getAccessTokenSilently } = useAuth0()
    const [profileData, setProfileData] = useState(null)
    const navigate = useNavigate();

    useEffect(() => {

        const getProfileData = async ()=> {
            const accessToken = await getAccessTokenSilently()
            console.log(accessToken)
            const fetchedProfileData = await (await fetch("http://127.0.0.1:5000/get-user-info",{
                headers:{
                    "Authorization":`Bearer ${accessToken}`
                }
            })).json()
            console.log(fetchedProfileData)
            setProfileData(fetchedProfileData)
        }

        if(!isAuthenticated && !isLoading){
            navigate("/")
        }
        else{
            getProfileData()
        }
    }, [getAccessTokenSilently, isAuthenticated, isLoading, navigate])

    if (isLoading) {
        return (
            <div></div>
        )
    }

    return (
        <div>
            
        </div>
    )
}

export default Profile
