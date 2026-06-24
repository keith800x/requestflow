import { useEffect, useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { getCurrentUser, type User } from "../api/authApi";
import "./AppLayout.css";

export default function AppLayout() {
  const navigate = useNavigate();

  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    async function loadUser() {
      try {
        const currentUser = await getCurrentUser();
        setUser(currentUser);
      } catch {
        localStorage.removeItem("access_token");
        navigate("/");
      }
    }

    loadUser();
  }, [navigate]);

  function handleLogout() {
    localStorage.removeItem("access_token");
    navigate("/");
  }

  return (
    <div className="app-layout">
      <header className="app-header">
        <div className="app-header-content">
          <NavLink to="/dashboard" className="app-logo">
            RequestFlow
          </NavLink>

          <nav className="app-nav">
            <NavLink to="/dashboard" className={getNavLinkClass}>
              Dashboard
            </NavLink>

            <NavLink to="/requests" className={getNavLinkClass}>
              My Requests
            </NavLink>

            <NavLink to="/requests/new" className={getNavLinkClass}>
              Create Request
            </NavLink>

            {user?.role === "ADMIN" && (
              <NavLink to="/admin/requests" className={getNavLinkClass}>
                All Requests
              </NavLink>
            )}
          </nav>

          <div className="app-user-area">
            {user && (
              <span className="app-user-text">
                {user.name} ({user.role})
              </span>
            )}

            <button className="logout-button" onClick={handleLogout}>
              Logout
            </button>
          </div>
        </div>
      </header>

      <main className="app-main">
        <Outlet />
      </main>
    </div>
  );
}

function getNavLinkClass({ isActive }: { isActive: boolean }) {
  return isActive ? "app-nav-link active" : "app-nav-link";
}