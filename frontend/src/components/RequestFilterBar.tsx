import type { RequestFilterValues, RequestSortOption } from "../utils/requestFilters";


type RequestFilterBarProps = {
  filters: RequestFilterValues;
  onChange: (filters: RequestFilterValues) => void;
  onClear: () => void;
};

export default function RequestFilterBar({
  filters,
  onChange,
  onClear,
}: RequestFilterBarProps) {
  return (
    <section
      style={{
        marginBottom: "20px",
        padding: "16px",
        border: "1px solid #ddd",
        borderRadius: "8px",
      }}
    >
      <div style={{ marginBottom: "12px" }}>
        <label htmlFor="request-search">Search</label>
        <input
          id="request-search"
          type="text"
          placeholder="Search by title or description"
          value={filters.search}
          onChange={(event) =>
            onChange({ ...filters, search: event.target.value })
          }
          style={{ display: "block", width: "100%", padding: "8px" }}
        />
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))",
          gap: "12px",
        }}
      >
        <div>
          <label htmlFor="status-filter">Status</label>
          <select
            id="status-filter"
            value={filters.status}
            onChange={(event) =>
              onChange({ ...filters, status: event.target.value })
            }
            style={{ display: "block", width: "100%", padding: "8px" }}
          >
            <option>All</option>
            <option>Open</option>
            <option>In Progress</option>
            <option>Resolved</option>
            <option>Closed</option>
          </select>
        </div>

        <div>
          <label htmlFor="category-filter">Category</label>
          <select
            id="category-filter"
            value={filters.category}
            onChange={(event) =>
              onChange({ ...filters, category: event.target.value })
            }
            style={{ display: "block", width: "100%", padding: "8px" }}
          >
            <option>All</option>
            <option>Hardware</option>
            <option>Software</option>
            <option>Account</option>
            <option>Network</option>
            <option>Other</option>
          </select>
        </div>

        <div>
          <label htmlFor="priority-filter">Priority</label>
          <select
            id="priority-filter"
            value={filters.priority}
            onChange={(event) =>
              onChange({ ...filters, priority: event.target.value })
            }
            style={{ display: "block", width: "100%", padding: "8px" }}
          >
            <option>All</option>
            <option>Low</option>
            <option>Medium</option>
            <option>High</option>
          </select>
        </div>

        <div>
          <label htmlFor="sort-filter">Sort</label>
          <select
            id="sort-filter"
            value={filters.sort}
            onChange={(event) =>
              onChange({
                ...filters,
                sort: event.target.value as RequestSortOption,
              })
            }
            style={{ display: "block", width: "100%", padding: "8px" }}
          >
            <option value="newest">Newest first</option>
            <option value="oldest">Oldest first</option>
            <option value="priority-high">Priority: High to Low</option>
            <option value="priority-low">Priority: Low to High</option>
          </select>
        </div>
      </div>

      <button type="button" onClick={onClear} style={{ marginTop: "12px" }}>
        Clear Filters
      </button>
    </section>
  );
}