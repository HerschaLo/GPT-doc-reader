import { Outlet } from "react-router-dom";
import NavBar from "./navbar";
const Layout = ()=>{
    return (<div className="bg-slate-900 w-screen grid justify-items-center">
        <NavBar/>
        <Outlet />
    </div>)
}

export default Layout
