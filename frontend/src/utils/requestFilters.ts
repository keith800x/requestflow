export type RequestSortOption = "newest" | "oldest" | "priority-high" | "priority-low";

export type RequestFilterValues = {
  search: string;
  status: string;
  category: string;
  priority: string;
  sort: RequestSortOption;
};

type FilterableRequest = {
  title: string;
  description: string;
  status: string;
  category: string;
  priority: string;
  created_at: string;
};

const priorityRank: Record<string, number> = {
  High: 3,
  Medium: 2,
  Low: 1,
};

export function filterAndSortRequests<T extends FilterableRequest>(
  requests: T[],
  filters: RequestFilterValues
): T[] {
  const searchText = filters.search.trim().toLowerCase();

  const filteredRequests = requests.filter((request) => {
    const matchesSearch =
      request.title.toLowerCase().includes(searchText) ||
      request.description.toLowerCase().includes(searchText);

    const matchesStatus =
      filters.status === "All" || request.status === filters.status;

    const matchesCategory =
      filters.category === "All" || request.category === filters.category;

    const matchesPriority =
      filters.priority === "All" || request.priority === filters.priority;

    return matchesSearch && matchesStatus && matchesCategory && matchesPriority;
  });

  return filteredRequests.sort((a, b) => {
    if (filters.sort === "newest") {
      return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
    }

    if (filters.sort === "oldest") {
      return new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
    }

    if (filters.sort === "priority-high") {
      return priorityRank[b.priority] - priorityRank[a.priority];
    }

    if (filters.sort === "priority-low") {
      return priorityRank[a.priority] - priorityRank[b.priority];
    }

    return 0;
  });
}