import { Link } from "react-router-dom";
import clipartRobo from "../assets/clipartRobo.PNG"
import LoginButton from "./login-button";
import SignupButton from "./signup-button";
import { useAuth0 } from "@auth0/auth0-react";
import {useNavigate} from "react-router-dom"
const NavBar = ()=>{
    const {isAuthenticated, logout, isLoading} = useAuth0()
    const navigate = useNavigate()

    const handleNavigate = () =>{
        if(!isAuthenticated){
            navigate("/")
        } else{
            navigate("/profile")
        }
    }

    if(isLoading){
        return (<></>)
    }

    return (
    <div className="bg-slate-800 h-20 shadow-lg w-screen flex justify-between items-center pl-8">
        <img src={clipartRobo} onClick={handleNavigate} className="object-contain h-16 hover:cursor-pointer" />
        <div className="flex gap-x-7 items-center w-1/4 justify-end pr-8">
        {!isAuthenticated ? 
        <>
            <SignupButton />
            <LoginButton />
        </>
        :
        <>
            <button className="bg-red-500" onClick={()=>{logout({ logoutParams: { returnTo: window.location.origin } })}}>Logout</button>
            <Link to="/profile">Profile</Link>
        </>
        }
        </div>
    </div>
    )
}

export default NavBar
