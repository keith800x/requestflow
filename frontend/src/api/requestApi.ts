import { apiClient } from "./apiClient";

export type RequestCategory =
  | "Hardware"
  | "Software"
  | "Account"
  | "Network"
  | "Other";

export type RequestPriority = "Low" | "Medium" | "High";

export type RequestStatus =
  | "Open"
  | "In Progress"
  | "Resolved"
  | "Closed";

export type ServiceRequest = {
  id: number;
  title: string;
  description: string;
  category: RequestCategory;
  priority: RequestPriority;
  status: RequestStatus;
  created_by_id: number;
  assigned_to_id: number | null;
  created_at: string;
  updated_at: string;
};

export type CreateRequestPayload = {
  title: string;
  description: string;
  category: RequestCategory;
  priority: RequestPriority;
};

export type UpdateRequestPayload = {
  title?: string;
  description?: string;
  category?: RequestCategory;
  priority?: RequestPriority;
  status?: RequestStatus;
  assigned_to_id?: number | null;
};


export async function getMyRequests(): Promise<ServiceRequest[]> {
  const response = await apiClient.get<ServiceRequest[]>("/requests/my");
  return response.data;
}

export async function getAllRequests(): Promise<ServiceRequest[]> {
  const response = await apiClient.get<ServiceRequest[]>("/requests/");
  return response.data;
}

export async function getRequestById(
  requestId: number
): Promise<ServiceRequest> {
  const response = await apiClient.get<ServiceRequest>(`/requests/${requestId}`);
  return response.data;
}

export async function createServiceRequest(
  payload: CreateRequestPayload
): Promise<ServiceRequest> {
  const response = await apiClient.post<ServiceRequest>("/requests/", payload);
  return response.data;
}

export async function updateServiceRequest(
  requestId: number,
  payload: UpdateRequestPayload
): Promise<ServiceRequest> {
  const response = await apiClient.patch<ServiceRequest>(
    `/requests/${requestId}`,
    payload
  );

  return response.data;
}

export async function deleteServiceRequest(requestId: number): Promise<void> {
  await apiClient.delete(`/requests/${requestId}`);
}