import * as React from "react";
import * as ReactDOM from "react-dom/client";
import {
  createBrowserRouter,
  RouterProvider,
} from "react-router-dom";
import "./index.css";
import Index from "./pages";
import Auth from "./pages/auth";

const router = createBrowserRouter([
  {
    path: "/",
    element: <Index/>,
  },
    {
      path: "/auth",
    element: <Auth/>,
    }

]);

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>
);
