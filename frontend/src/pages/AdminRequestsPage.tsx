import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  deleteServiceRequest,
  getAllRequests,
  updateServiceRequest,
  type RequestStatus,
  type ServiceRequest,
} from "../api/requestApi";
import { getCurrentUser, type User } from "../api/authApi";

const statuses: RequestStatus[] = [
  "Open",
  "In Progress",
  "Resolved",
  "Closed",
];

export default function AdminRequestsPage() {
  const navigate = useNavigate();

  const [user, setUser] = useState<User | null>(null);
  const [requests, setRequests] = useState<ServiceRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadAdminData() {
      try {
        const currentUser = await getCurrentUser();

        if (currentUser.role !== "ADMIN") {
          setError("You do not have admin access.");
          return;
        }

        setUser(currentUser);

        const requestData = await getAllRequests();
        setRequests(requestData);
      } catch {
        setError("Failed to load all requests. Please login again.");
        localStorage.removeItem("access_token");
        navigate("/");
      } finally {
        setIsLoading(false);
      }
    }

    loadAdminData();
  }, [navigate]);

  async function handleStatusChange(
    requestId: number,
    newStatus: RequestStatus
  ) {
    try {
      const updatedRequest = await updateServiceRequest(requestId, {
        status: newStatus,
      });

      setRequests((currentRequests) =>
        currentRequests.map((request) =>
          request.id === requestId ? updatedRequest : request
        )
      );
    } catch {
      setError("Failed to update request status.");
    }
  }

  async function handleDelete(requestId: number) {
  const confirmed = window.confirm(
    "Are you sure you want to delete this request?"
  );

  if (!confirmed) {
    return;
  }

  try {
    await deleteServiceRequest(requestId);

    setRequests((currentRequests) =>
      currentRequests.filter((request) => request.id !== requestId)
    );
  } catch {
    setError("Failed to delete request.");
  }
}

  return (
    <main style={{ maxWidth: "1100px", margin: "40px auto" }}>
      <header style={{ marginBottom: "24px" }}>
        <h1>All Requests</h1>
      </header>

      {user && (
        <p>
          Admin: <strong>{user.name}</strong>
        </p>
      )}

      {isLoading && <p>Loading all requests...</p>}

      {error && <p style={{ color: "red" }}>{error}</p>}

      {!isLoading && !error && requests.length === 0 && (
        <p>No service requests found.</p>
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
              <th style={tableHeaderStyle}>Created By</th>
              <th style={tableHeaderStyle}>Created</th>
              <th style={tableHeaderStyle}>Actions</th>
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
                <td style={tableCellStyle}>
                  <select
                    value={request.status}
                    onChange={(event) =>
                      handleStatusChange(
                        request.id,
                        event.target.value as RequestStatus
                      )
                    }
                  >
                    {statuses.map((statusOption) => (
                      <option key={statusOption} value={statusOption}>
                        {statusOption}
                      </option>
                    ))}
                  </select>
                </td>
                <td style={tableCellStyle}>{request.created_by_id}</td>
                <td style={tableCellStyle}>
                  {new Date(request.created_at).toLocaleString()}
                </td>

                <td style={tableCellStyle}>
                  <button onClick={() => handleDelete(request.id)}>Delete</button>
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