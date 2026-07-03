import { useMemo, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { getMyRequests, type ServiceRequest } from "../api/requestApi";
import RequestFilterBar from "../components/RequestFilterBar";
import {
  filterAndSortRequests,
  type RequestFilterValues,
} from "../utils/requestFilters";

import { formatDateTime } from "../utils/dateFormat";

const defaultFilters: RequestFilterValues = {
  search: "",
  status: "All",
  category: "All",
  priority: "All",
  sort: "newest",
};


export default function MyRequestsPage() {
  const [requests, setRequests] = useState<ServiceRequest[]>([]);
  const [filters, setFilters] = useState<RequestFilterValues>(defaultFilters);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");

  const filteredRequests = useMemo(() => {
    return filterAndSortRequests(requests, filters);
  }, [requests, filters]);

  
  async function loadRequests() {
    setIsLoading(true);
    setError("");

    try {
      const data = await getMyRequests();
      setRequests(data);
    } catch {
      setError(
        "Failed to load requests. The backend may still be waking up. Please try again."
      );
    } finally {
      setIsLoading(false);
    }
  }


  useEffect(() => {
    loadRequests();
  }, []);

  return (
    <main style={{ maxWidth: "1000px", margin: "40px auto" }}>
      <header style={{ marginBottom: "24px" }}>
        <h1>My Requests</h1>
      </header>

      {isLoading && <p>Loading requests...</p>}

      {!isLoading && error && (
        <div>
          <p style={{ color: "red" }}>{error}</p>
          <button type="button" onClick={loadRequests}>
            Try Again
          </button>
        </div>
      )}

      {!isLoading && !error && requests.length === 0 && (
        <p>You have not created any requests yet.</p>
      )}

      {!isLoading && !error && requests.length > 0 && (
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
                  <th style={tableHeaderStyle}>Created</th>
                </tr>
              </thead>

              <tbody>
                {filteredRequests.map((request) => (
                  <tr key={request.id}>
                    <td style={tableCellStyle}>{request.id}</td>
                    <td style={tableCellStyle}>
                      <Link to={`/requests/${request.id}`}>
                        {request.title}
                      </Link>
                    </td>
                    <td style={tableCellStyle}>{request.category}</td>
                    <td style={tableCellStyle}>{request.priority}</td>
                    <td style={tableCellStyle}>{request.status}</td>
                    <td style={tableCellStyle}>
                      {formatDateTime(request.created_at)}
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