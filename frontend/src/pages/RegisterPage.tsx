import { useState, type SubmitEventHandler } from "react";
import { Link, useNavigate } from "react-router-dom";
import { registerUser } from "../api/authApi";

export default function RegisterPage() {
  const navigate = useNavigate();

  const [name, setName] = useState("Keith");
  const [email, setEmail] = useState("keith@example.com");
  const [password, setPassword] = useState("password123");
  const [error, setError] = useState("");

  const handleSubmit: SubmitEventHandler<HTMLFormElement> = async (event) => 
    {
      event.preventDefault();
      setError("");

      try {
        await registerUser({
          name,
          email,
          password,
        });

        navigate("/");
      } catch {
        setError("Registration failed. The email may already be registered.");
      }
    };

  return (
    <main style={{ maxWidth: "420px", margin: "40px auto" }}>
      <h1>Create Account</h1>

      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: "12px" }}>
          <label htmlFor="name">Name</label>
          <input 
            id="name"
            style={{ display: "block", width: "100%", padding: "8px" }}
            value={name}
            onChange={(event) => setName(event.target.value)}
          />
        </div>

        <div style={{ marginBottom: "12px" }}>
          <label htmlFor="email">Email</label>
          <input 
            id="email"
            style={{ display: "block", width: "100%", padding: "8px" }}
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            type="email"
          />
        </div>

        <div style={{ marginBottom: "12px" }}>
          <label htmlFor="password">Password</label>
          <input
            id="password"
            style={{ display: "block", width: "100%", padding: "8px" }}
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            type="password"
          />
        </div>

        {error && <p style={{ color: "red" }}>{error}</p>}

        <button type="submit">Register</button>
      </form>

      <p>
        Already have an account? <Link to="/">Login here</Link>
      </p>
    </main>
  );
}