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
import Layout from "./components/layout";
import Auth0ProviderWithNavigate from "./components/auth0-provider-with-navigate";
import Profile from "./pages/profile";
import BotConversations from "./pages/bot-conversations"
import UserBotDisplay from "./pages/my-bots"
import UserFileDisplay from "./pages/my-files"
const router = createBrowserRouter(
  createRoutesFromElements(
    <Route path="/" element={
      <Auth0ProviderWithNavigate>
        <Layout />
      </Auth0ProviderWithNavigate>
    }>
        <Route index element={<Index />}/>
        <Route element={<Profile />} path="/profile"/>
        <Route element={<BotConversations />} path="/bot-conversations"/>
        <Route element={<UserBotDisplay />} path="/my-bots"/>
        <Route element={<UserFileDisplay />} path="/my-files"/>
    </Route>
  )
);

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
      <RouterProvider router={router} />
  </React.StrictMode>
);
