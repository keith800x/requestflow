import { useEffect, useState, type SubmitEventHandler } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { getCurrentUser, type User } from "../api/authApi";
import {
  deleteServiceRequest,
  getRequestById,
  updateServiceRequest,
  type RequestStatus,
  type ServiceRequest,
} from "../api/requestApi";
import {
  createComment,
  getCommentsForRequest,
  type Comment,
} from "../api/commentApi";

const statuses: RequestStatus[] = [
  "Open",
  "In Progress",
  "Resolved",
  "Closed",
];

export default function RequestDetailPage() {
  const navigate = useNavigate();
  const params = useParams();

  const requestId = Number(params.requestId);

  const [user, setUser] = useState<User | null>(null);
  const [serviceRequest, setServiceRequest] = useState<ServiceRequest | null>(
    null
  );
  const [comments, setComments] = useState<Comment[]>([]);
  const [message, setMessage] = useState("");
  const [isInternalNote, setIsInternalNote] = useState(false);
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  const isAdmin = user?.role === "ADMIN";

  useEffect(() => {
    async function loadDetail() {
      try {
        const currentUser = await getCurrentUser();
        setUser(currentUser);

        const requestData = await getRequestById(requestId);
        setServiceRequest(requestData);

        const commentData = await getCommentsForRequest(requestId);
        setComments(commentData);
      } catch {
        setError("Failed to load request details.");
      } finally {
        setIsLoading(false);
      }
    }

    if (!Number.isNaN(requestId)) {
      loadDetail();
    }
  }, [requestId]);

  async function handleStatusChange(newStatus: RequestStatus) {
    if (!serviceRequest) {
      return;
    }

    try {
      const updatedRequest = await updateServiceRequest(serviceRequest.id, {
        status: newStatus,
      });

      setServiceRequest(updatedRequest);
    } catch {
      setError("Failed to update request status.");
    }
  }

  async function handleDelete() {
    if (!serviceRequest) {
      return;
    }

    const confirmed = window.confirm(
      "Are you sure you want to delete this request?"
    );

    if (!confirmed) {
      return;
    }

    try {
      await deleteServiceRequest(serviceRequest.id);
      navigate("/admin/requests");
    } catch {
      setError("Failed to delete request.");
    }
  }

  const handleCreateComment: SubmitEventHandler<HTMLFormElement> = async (event) => 
  {
    event.preventDefault();
    setError("");

    try {
      const newComment = await createComment(requestId, {
        message,
        is_internal_note: isInternalNote,
      });

      setComments((currentComments) => [...currentComments, newComment]);
      setMessage("");
      setIsInternalNote(false);
    } catch {
      setError("Failed to create comment.");
    }
  };

  if (isLoading) {
    return (
      <main style={{ maxWidth: "900px", margin: "40px auto" }}>
        <p>Loading request details...</p>
      </main>
    );
  }

  if (!serviceRequest) {
    return (
      <main style={{ maxWidth: "900px", margin: "40px auto" }}>
        <p style={{ color: "red" }}>{error || "Request not found."}</p>
        <Link to="/dashboard">Back to Dashboard</Link>
      </main>
    );
  }

  return (
    <main style={{ maxWidth: "900px", margin: "40px auto" }}>
      <header style={{ marginBottom: "24px" }}>
        <h1>Request #{serviceRequest.id}</h1>
      </header>

      {error && <p style={{ color: "red" }}>{error}</p>}

      <section
        style={{
          border: "1px solid #ccc",
          padding: "16px",
          marginBottom: "24px",
        }}
      >
        <h2>{serviceRequest.title}</h2>

        <p>{serviceRequest.description}</p>

        <p>
          <strong>Category:</strong> {serviceRequest.category}
        </p>

        <p>
          <strong>Priority:</strong> {serviceRequest.priority}
        </p>

        <p>
          <strong>Status:</strong> {serviceRequest.status}
        </p>

        <p>
          <strong>Created by user ID:</strong> {serviceRequest.created_by_id}
        </p>

        <p>
          <strong>Created:</strong>{" "}
          {new Date(serviceRequest.created_at).toLocaleString()}
        </p>

        {isAdmin && (
          <div style={{ marginTop: "16px" }}>
            <label>Admin status update</label>
            <select
              style={{ display: "block", padding: "8px", marginTop: "4px" }}
              value={serviceRequest.status}
              onChange={(event) =>
                handleStatusChange(event.target.value as RequestStatus)
              }
            >
              {statuses.map((statusOption) => (
                <option key={statusOption} value={statusOption}>
                  {statusOption}
                </option>
              ))}
            </select>

            <button
              onClick={handleDelete}
              style={{ marginTop: "12px", color: "red" }}
            >
              Delete Request
            </button>
          </div>
        )}
      </section>

      <section
        style={{
          border: "1px solid #ccc",
          padding: "16px",
          marginBottom: "24px",
        }}
      >
        <h2>Comments</h2>

        {comments.length === 0 && <p>No comments yet.</p>}

        {comments.map((comment) => (
          <article
            key={comment.id}
            style={{
              borderBottom: "1px solid #ddd",
              paddingTop: "8px",
              paddingBottom: "8px",
            }}
          >
            <p>{comment.message}</p>

            <small>
              User ID: {comment.user_id} |{" "}
              {new Date(comment.created_at).toLocaleString()}
              {comment.is_internal_note && (
                <strong style={{ color: "darkred" }}> | Internal Note</strong>
              )}
            </small>
          </article>
        ))}
      </section>

      <section
        style={{
          border: "1px solid #ccc",
          padding: "16px",
        }}
      >
        <h2>Add Comment</h2>

        <form onSubmit={handleCreateComment}>
          <textarea
            style={{
              display: "block",
              width: "100%",
              minHeight: "100px",
              padding: "8px",
              marginBottom: "12px",
            }}
            value={message}
            onChange={(event) => setMessage(event.target.value)}
            placeholder="Write a comment..."
          />

          {isAdmin && (
            <label style={{ display: "block", marginBottom: "12px" }}>
              <input
                type="checkbox"
                checked={isInternalNote}
                onChange={(event) => setIsInternalNote(event.target.checked)}
              />{" "}
              Internal admin note
            </label>
          )}

          <button type="submit">Add Comment</button>
        </form>
      </section>
    </main>
  );
}