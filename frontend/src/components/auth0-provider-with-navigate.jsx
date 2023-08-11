import { Auth0Provider } from "@auth0/auth0-react";
import { useNavigate,} from "react-router-dom";
import { PropTypes } from "prop-types";

export const Auth0ProviderWithNavigate = ({ children }) => {
  const navigate = useNavigate();
  
  const onRedirectCallback = async (appState) => {
    console.log("redirecting callback activated")
    
    
    navigate(appState?.returnTo || window.location.pathname);
  };

  return (
    <Auth0Provider
        domain="dev-4et1s8fqfxunww8q.us.auth0.com"
        clientId="5Iu6Wr7yLpiQClPpRIzdyoULsIcQH5UY"
        authorizationParams={{
            redirect_uri: window.location.origin,
            audience:"gpt-doc-reader-api",
            scope:"ordinary_user"
        }}
        onRedirectCallback={onRedirectCallback}
    >
      {children}
    </Auth0Provider>
  );
};

Auth0ProviderWithNavigate.propTypes = {
  children: PropTypes.object
}

export default Auth0ProviderWithNavigate
