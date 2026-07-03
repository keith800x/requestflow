import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import RequestFilterBar from "../components/RequestFilterBar";

import {
  filterAndSortRequests,
  type RequestFilterValues,
} from "../utils/requestFilters";

import {
  deleteServiceRequest,
  getAllRequests,
  updateServiceRequest,
  type RequestStatus,
  type ServiceRequest,
} from "../api/requestApi";

import { getCurrentUser, type User } from "../api/authApi";

import { formatDateTime } from "../utils/dateFormat";

const defaultFilters: RequestFilterValues = {
  search: "",
  status: "All",
  category: "All",
  priority: "All",
  sort: "newest",
};

const statuses: RequestStatus[] = [
  "Open",
  "In Progress",
  "Resolved",
  "Closed",
];

export default function AdminRequestsPage() {

  const [user, setUser] = useState<User | null>(null);
  const [requests, setRequests] = useState<ServiceRequest[]>([]);
  const [filters, setFilters] = useState<RequestFilterValues>(defaultFilters);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");


  const filteredRequests = useMemo(() => {
    return filterAndSortRequests(requests, filters);
  }, [requests, filters]);

  async function loadAdminData() {
    setIsLoading(true);
    setError("");

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
      setError(
        "Failed to load all requests. The backend may still be waking up. Please try again."
      );
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    loadAdminData();
  }, []);


  async function handleStatusChange(
    requestId: number,
    newStatus: RequestStatus
  ) {
    setError("");

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
      setError("Failed to update request status. Please try again.");
    }
  }

  async function handleDelete(requestId: number) {
  const confirmed = window.confirm(
    "Are you sure you want to delete this request?"
  );

  if (!confirmed) {
    return;
  }

    setError("");


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

      {!isLoading && error && (
        <div>
          <p style={{ color: "red" }}>{error}</p>
          <button type="button" onClick={loadAdminData}>
            Try Again
          </button>
        </div>
      )}


      {!isLoading && !error && requests.length === 0 && (
        <p>No service requests found.</p>
      )}

      {!isLoading && requests.length > 0 && (

        <>
            <RequestFilterBar
              filters={filters}
              onChange={setFilters}
              onClear={() => setFilters(defaultFilters)}
            />

            {filteredRequests.length === 0 ? (
            <p>No requests match the current filters.</p>
          ) : (
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
                {filteredRequests.map((request) => (
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
                      {formatDateTime(request.created_at)}
                    </td>

                    <td style={tableCellStyle}>
                      <button onClick={() => handleDelete(request.id)}>Delete</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </>
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