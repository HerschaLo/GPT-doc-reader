import { useAuth0 } from "@auth0/auth0-react"
import { redirect } from "react-router-dom";
import { useEffect } from "react";
const Profile = () => {
    const { isLoading, isAuthenticated, getAccessTokenSilently, user } = useAuth0()

    useEffect(() => {
        const getProfileData = async ()=> {
            const accessToken = await getAccessTokenSilently()
            console.log(accessToken)
            const profileData = await (await fetch("http://127.0.0.1:5000/get-user-info",{
                headers:{
                    "Authorization":`Bearer ${accessToken}`
                }
            })).json()
            console.log(profileData)
        }
        getProfileData()
    }, [getAccessTokenSilently, user?.sub])
    if (isLoading) {
        return (
            <div></div>
        )
    }
    if (!isAuthenticated) {
        return redirect("/")
    }

    return (
        <div></div>
    )
}

export default Profile
