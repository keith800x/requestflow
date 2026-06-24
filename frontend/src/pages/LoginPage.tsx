import { useState, type SubmitEventHandler } from "react";
import { useNavigate, Link } from "react-router-dom";
import { loginUser } from "../api/authApi";

export default function LoginPage() {
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");

  const handleSubmit: SubmitEventHandler<HTMLFormElement> = async (event) => 
  {
    event.preventDefault();
    setError("");

    try {
      const tokenResponse = await loginUser({
        email,
        password,
      });

      localStorage.setItem("access_token", tokenResponse.access_token);

      navigate("/dashboard");
    } catch {
      setError("Login failed. Please check your email and password.");
    }
  };

  return (
    <main style={{ margin: "40px auto", padding: "0 16px" }}>
      <header style={{ textAlign: "center", marginBottom: "32px" }}>
        <h1>IT Service Request Tracker</h1>
        <p style={{ color: "#666" }}>
          Submit, track, and manage IT service requests.
        </p>
      </header>

      <section style={{ maxWidth: "420px", margin: "0 auto" }}>
        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: "12px" }}>
            <label>Email</label>
            <input
              style={{ display: "block", width: "100%", padding: "8px" }}
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              type="email"
              required
            />
          </div>

          <div style={{ marginBottom: "12px" }}>
            <label>Password</label>
            <input
              style={{ display: "block", width: "100%", padding: "8px" }}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              type="password"
              required
            />
          </div>

          {error && <p style={{ color: "red" }}>{error}</p>}

          <button type="submit">Login</button>
        </form>

        <p>
          No account? <Link to="/register">Register here</Link>
        </p>
      </section>
    </main>
  );
}