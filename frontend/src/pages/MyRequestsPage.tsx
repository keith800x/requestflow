import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { getMyRequests, type ServiceRequest } from "../api/requestApi";

export default function MyRequestsPage() {
  const navigate = useNavigate();

  const [requests, setRequests] = useState<ServiceRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadRequests() {
      try {
        const data = await getMyRequests();
        setRequests(data);
      } catch {
        setError("Failed to load requests. Please login again.");
        localStorage.removeItem("access_token");
        navigate("/");
      } finally {
        setIsLoading(false);
      }
    }

    loadRequests();
  }, [navigate]);

  return (
    <main style={{ maxWidth: "1000px", margin: "40px auto" }}>
      <header style={{ marginBottom: "24px" }}>
        <h1>My Requests</h1>
      </header>

      {isLoading && <p>Loading requests...</p>}

      {error && <p style={{ color: "red" }}>{error}</p>}

      {!isLoading && !error && requests.length === 0 && (
        <p>You have not created any requests yet.</p>
      )}

      {!isLoading && requests.length > 0 && (
        <table
          style={{
            width: "100%",
            borderCollapse: "collapse",
          }}
        >
          <thead>
            <tr>
              <th style={tableHeaderStyle}>ID</th>
              <th style={tableHeaderStyle}>Title</th>
              <th style={tableHeaderStyle}>Category</th>
              <th style={tableHeaderStyle}>Priority</th>
              <th style={tableHeaderStyle}>Status</th>
              <th style={tableHeaderStyle}>Created</th>
            </tr>
          </thead>

          <tbody>
            {requests.map((request) => (
              <tr key={request.id}>
                <td style={tableCellStyle}>{request.id}</td>
                <td style={tableCellStyle}> 
                  <Link to={`/requests/${request.id}`}>{request.title}</Link>
                </td>
                <td style={tableCellStyle}>{request.category}</td>
                <td style={tableCellStyle}>{request.priority}</td>
                <td style={tableCellStyle}>{request.status}</td>
                <td style={tableCellStyle}>
                  {new Date(request.created_at).toLocaleString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </main>
  );
}

const tableHeaderStyle = {
  border: "1px solid #ccc",
  padding: "8px",
  textAlign: "left" as const,
  backgroundColor: "#f5f5f5",
};

const tableCellStyle = {
  border: "1px solid #ccc",
  padding: "8px",
};