import * as React from "react";
import * as ReactDOM from "react-dom/client";
import {
  createBrowserRouter,
  RouterProvider,
  createRoutesFromElements,
  Route
} from "react-router-dom";
import "./main.scss";
import Index from "./pages";
import Auth from "./pages/auth";
import Layout from "./components/layout";
import { Auth0Provider } from '@auth0/auth0-react';

const router = createBrowserRouter(
  createRoutesFromElements(
    <Route path="/" element={<Layout />}>
        <Route index element={<Index />}/>
        <Route path="/auth" element={<Auth />}/>
    </Route>
  )
);

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <Auth0Provider
      domain="dev-4et1s8fqfxunww8q.us.auth0.com"
      clientId="5Iu6Wr7yLpiQClPpRIzdyoULsIcQH5UY"
      authorizationParams={{
        redirect_uri: window.location.origin
      }}
    >
      <RouterProvider router={router} />
    </Auth0Provider>
  </React.StrictMode>
);
