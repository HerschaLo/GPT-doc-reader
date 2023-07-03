import { Link } from "react-router-dom";
import clipartRobo from "../assets/clipartRobo.PNG"
const NavBar = ()=>{
    return (
    <div className="bg-slate-800 h-20 shadow-lg w-screen flex justify-between items-center pl-8">
            <img src={clipartRobo} className="object-contain h-16" />
        <div className="flex gap-x-7 items-center w-1/4 justify-end pr-8">
            <Link to="/">Home</Link>
            <Link to="/signup">Sign up</Link>
            <Link to="/auth">Login</Link>
        </div>
    </div>
    )
}

export default NavBar
