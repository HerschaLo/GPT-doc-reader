import '../styles/auth.scss'
import { useAuth0 } from "@auth0/auth0-react";
const SignupButton = () => {
    const { loginWithRedirect } = useAuth0();

    const handleSignUp = async () => {
        await loginWithRedirect({
          appState: {
            returnTo: "/",
            action:"signup"
          },
          authorizationParams: {
            screen_hint: "signup",
          },
        });
    };
    return (
      <button onClick={handleSignUp}>Sign up</button>
    )
}

export default SignupButton
