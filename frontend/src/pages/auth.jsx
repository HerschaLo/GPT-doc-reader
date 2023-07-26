import '../styles/auth.scss'
import { useAuth0 } from "@auth0/auth0-react";

const Auth = () => {
    const { loginWithRedirect } = useAuth0();
    return (
        <div className='cont'>
            <div className='formBody'>lorem ipsum</div>
            <button onClick={loginWithRedirect}></button>
        </div>
    )
}

export default Auth
