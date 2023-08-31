import { Outlet } from "react-router-dom";
import NavBar from "./navbar";
import { useAuth0 } from "@auth0/auth0-react";
import { useEffect, useState, createContext} from "react";
import { useNavigate, useLocation} from "react-router-dom";

let TokenContext = createContext(null);

const Layout = () => {
    const { isLoading, getAccessTokenSilently, isAuthenticated } = useAuth0()
    const [authCheckDone, setAuthCheckDone] = useState(false)
    const navigate = useNavigate()
    const location = useLocation()

    useEffect(()=>{
        console.log("effect activated")

        const authCheck = async () =>{
            console.log("hi")
            if(!isLoading){
                console.log("hello")

                if(isAuthenticated){
                    console.log("hello2")
                    const accessToken = await getAccessTokenSilently()
                    TokenContext = createContext(accessToken)

                    await fetch("http://127.0.0.1:5000/login",{
                        method:"POST",
                        headers:{
                            "Authorization":`Bearer ${accessToken}`
                        }
                    })
                } else if(location.pathname != "/"){
                    navigate("/")
                }
                setAuthCheckDone(true)
            }
        }

        authCheck()
    },[getAccessTokenSilently, isAuthenticated, isLoading, location.pathname, navigate])

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

export {TokenContext}
