import { useEffect, useState } from "react";
import { Navigate, Outlet } from "react-router-dom";
import { getCurrentUser } from "../api/authApi";

export default function AdminRoute() {
  const [isLoading, setIsLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    async function checkAdminAccess() {
      try {
        const currentUser = await getCurrentUser();
        setIsAdmin(currentUser.role === "ADMIN");
      } catch {
        localStorage.removeItem("access_token");
        setIsAdmin(false);
      } finally {
        setIsLoading(false);
      }
    }

    checkAdminAccess();
  }, []);

  if (isLoading) {
    return <p>Loading...</p>;
  }

  if (!isAdmin) {
    return <Navigate to="/dashboard" replace />;
  }

  return <Outlet />;
}