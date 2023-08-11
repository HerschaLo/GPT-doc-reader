import { Outlet } from "react-router-dom";
import NavBar from "./navbar";
import { useAuth0 } from "@auth0/auth0-react";
import { useEffect, useState } from "react";
const Layout = () => {
    const { isLoading, getAccessTokenSilently, isAuthenticated } = useAuth0()
    const [authCheckDone, setAuthCheckDone] = useState(false)
    useEffect(()=>{
        console.log("effect activated")
        const authCheck = async () =>{
            console.log("hi")
            if(!isLoading){
                if(isAuthenticated){
                    const accessToken = await getAccessTokenSilently()
                    
                    await fetch("http://127.0.0.1:5000/login",{
                        method:"POST",
                        body:"",
                        headers:{
                            "Content-Type":"text/plain",
                            "Authorization":`Bearer ${accessToken}`
                        }
                    })
                }
                setAuthCheckDone(true)
            }
        }
        authCheck()
    },[isLoading])

    return (<div className="bg-slate-900 w-screen flex flex-col items-center overflow-x-hidden">
        {authCheckDone ?
            <>
                <NavBar />
                <Outlet />
            </>
            :
            null
        }
    </div>
    )
}

export default Layout
