import { useEffect, useState } from "react";
import { getCurrentUser, type User } from "../api/authApi";

export default function DashboardPage() {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    async function loadUser() {
      const currentUser = await getCurrentUser();
      setUser(currentUser);
    }

    loadUser();
  }, []);

  return (
    <section>
      <h1>Dashboard</h1>

      {user && (
        <div
          style={{
            border: "1px solid #ddd",
            backgroundColor: "white",
            padding: "20px",
            borderRadius: "12px",
            marginTop: "16px",
          }}
        >
          <h2>Welcome, {user.name}</h2>
          <p>Email: {user.email}</p>
          <p>Role: {user.role}</p>
        </div>
      )}
    </section>
  );
}