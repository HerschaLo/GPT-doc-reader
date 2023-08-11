import '../styles/auth.scss'
import { useAuth0 } from "@auth0/auth0-react";

const LoginButton = () => {
  const { loginWithRedirect } = useAuth0();

  const handleLogin = async () => {

    try {
      await loginWithRedirect({
        appState: {
          returnTo: "/",
          action: "login"
        },
      });
    } catch (e) {
      console.log(e.message);
    }
  };

  return (
    <button onClick={handleLogin}>Login</button>
  )
}

export default LoginButton
