import { apiClient } from "./apiClient";

export type Comment = {
  id: number;
  request_id: number;
  user_id: number;
  message: string;
  is_internal_note: boolean;
  created_at: string;
};

export type CreateCommentPayload = {
  message: string;
  is_internal_note: boolean;
};

export async function getCommentsForRequest(
  requestId: number
): Promise<Comment[]> {
  const response = await apiClient.get<Comment[]>(
    `/requests/${requestId}/comments`
  );

  return response.data;
}

export async function createComment(
  requestId: number,
  payload: CreateCommentPayload
): Promise<Comment> {
  const response = await apiClient.post<Comment>(
    `/requests/${requestId}/comments`,
    payload
  );

  return response.data;
}