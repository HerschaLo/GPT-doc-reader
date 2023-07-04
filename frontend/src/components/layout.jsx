import { Outlet } from "react-router-dom";
import NavBar from "./navbar";
const Layout = ()=>{
    return (<div className="bg-slate-900 w-screen flex flex-col items-center overflow-x-hidden">
        <NavBar/>
        <Outlet />
    </div>)
}

export default Layout
