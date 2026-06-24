import { useEffect, useState } from "react";
import { Navigate, Outlet } from "react-router-dom";
import { getCurrentUser } from "../api/authApi";

export default function ProtectedRoute() {
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    async function checkAuthentication() {
      try {
        await getCurrentUser();
        setIsAuthenticated(true);
      } catch {
        localStorage.removeItem("access_token");
        setIsAuthenticated(false);
      } finally {
        setIsLoading(false);
      }
    }

    checkAuthentication();
  }, []);

  if (isLoading) {
    return <p>Loading...</p>;
  }

  if (!isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
}