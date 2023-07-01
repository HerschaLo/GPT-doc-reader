import { Link } from "react-router-dom";

const NavBar = ()=>{
    return (
    <div className="bg-slate-800 w-full grid justify-items-end pr-8 align-middle">
        <div className="grid grid-flow-col gap-x-4 h-10">
            <Link to="/">Home</Link>
            <Link to="/auth">Login</Link>
        </div>
    </div>
    )
}

export default NavBar
