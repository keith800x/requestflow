import { useState, type SubmitEventHandler } from "react";
import { useNavigate } from "react-router-dom";
import {
  createServiceRequest,
  type RequestCategory,
  type RequestPriority,
} from "../api/requestApi";

const categories: RequestCategory[] = [
  "Hardware",
  "Software",
  "Account",
  "Network",
  "Other",
];

const priorities: RequestPriority[] = ["Low", "Medium", "High"];

export default function CreateRequestPage() {
  const navigate = useNavigate();

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState<RequestCategory>("Other");
  const [priority, setPriority] = useState<RequestPriority>("Medium");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit: SubmitEventHandler<HTMLFormElement> = async (event) => {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      await createServiceRequest({
        title,
        description,
        category,
        priority,
      });

      navigate("/requests");
    } catch {
      setError("Failed to create request. Please check your input or login again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <main style={{ maxWidth: "620px", margin: "40px auto" }}>
      <header style={{ marginBottom: "24px" }}>
        <h1>Create Service Request</h1>
      </header>

      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: "12px" }}>
          <label>Title</label>
          <input
            style={{ display: "block", width: "100%", padding: "8px" }}
            value={title}
            onChange={(event) => setTitle(event.target.value)}
            placeholder="Example: Laptop Wi-Fi keeps disconnecting"
          />
        </div>

        <div style={{ marginBottom: "12px" }}>
          <label>Description</label>
          <textarea
            style={{
              display: "block",
              width: "100%",
              minHeight: "120px",
              padding: "8px",
            }}
            value={description}
            onChange={(event) => setDescription(event.target.value)}
            placeholder="Describe the issue in detail."
          />
        </div>

        <div style={{ marginBottom: "12px" }}>
          <label>Category</label>
          <select
            style={{ display: "block", width: "100%", padding: "8px" }}
            value={category}
            onChange={(event) =>
              setCategory(event.target.value as RequestCategory)
            }
          >
            {categories.map((categoryOption) => (
              <option key={categoryOption} value={categoryOption}>
                {categoryOption}
              </option>
            ))}
          </select>
        </div>

        <div style={{ marginBottom: "12px" }}>
          <label>Priority</label>
          <select
            style={{ display: "block", width: "100%", padding: "8px" }}
            value={priority}
            onChange={(event) =>
              setPriority(event.target.value as RequestPriority)
            }
          >
            {priorities.map((priorityOption) => (
              <option key={priorityOption} value={priorityOption}>
                {priorityOption}
              </option>
            ))}
          </select>
        </div>

        {error && <p style={{ color: "red" }}>{error}</p>}

        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? "Creating..." : "Create Request"}
        </button>
      </form>
    </main>
  );
}