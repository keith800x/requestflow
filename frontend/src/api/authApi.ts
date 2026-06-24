import { apiClient } from "./apiClient";

export type RegisterPayload = {
  name: string;
  email: string;
  password: string;
};

export type LoginPayload = {
  email: string;
  password: string;
};

export type User = {
  id: number;
  name: string;
  email: string;
  role: "USER" | "ADMIN";
  created_at: string;
};

export type TokenResponse = {
  access_token: string;
  token_type: string;
};

export async function registerUser(payload: RegisterPayload): Promise<User> {
  const response = await apiClient.post<User>("/auth/register", payload);
  return response.data;
}

export async function loginUser(payload: LoginPayload): Promise<TokenResponse> {
  const response = await apiClient.post<TokenResponse>("/auth/login", payload);
  return response.data;
}

export async function getCurrentUser(): Promise<User> {
  const response = await apiClient.get<User>("/auth/me");
  return response.data;
}