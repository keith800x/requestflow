import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { beforeEach, describe, expect, test, vi } from "vitest";
import AppLayout from "./AppLayout";
import { getCurrentUser } from "../api/authApi";

vi.mock("../api/authApi", () => ({
  getCurrentUser: vi.fn(),
}));

describe("AppLayout", () => {
  beforeEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
  });

  test("shows normal user navigation", async () => {
    vi.mocked(getCurrentUser).mockResolvedValue({
      id: 1,
      name: "Normal User",
      email: "user@example.com",
      role: "USER",
      created_at: "2026-01-01T00:00:00Z",
    });

    render(
      <MemoryRouter initialEntries={["/dashboard"]}>
        <Routes>
          <Route element={<AppLayout />}>
            <Route path="/dashboard" element={<p>Dashboard content</p>} />
          </Route>
        </Routes>
      </MemoryRouter>
    );

    expect(await screen.findByText(/dashboard content/i)).toBeInTheDocument();

    expect(
      screen.getByRole("link", { name: /^dashboard$/i })
    ).toBeInTheDocument();

    expect(
      screen.getByRole("link", { name: /my requests/i })
    ).toBeInTheDocument();

    expect(
      screen.getByRole("link", { name: /create request/i })
    ).toBeInTheDocument();

    await waitFor(() => {
      expect(
        screen.queryByRole("link", { name: /all requests/i })
      ).not.toBeInTheDocument();
    });
  });

  test("shows admin navigation for admin users", async () => {
    vi.mocked(getCurrentUser).mockResolvedValue({
      id: 2,
      name: "Admin User",
      email: "admin@example.com",
      role: "ADMIN",
      created_at: "2026-01-01T00:00:00Z",
    });

    render(
      <MemoryRouter initialEntries={["/dashboard"]}>
        <Routes>
          <Route element={<AppLayout />}>
            <Route path="/dashboard" element={<p>Dashboard content</p>} />
          </Route>
        </Routes>
      </MemoryRouter>
    );

    expect(await screen.findByText(/dashboard content/i)).toBeInTheDocument();

    expect(
      screen.getByRole("link", { name: /^dashboard$/i })
    ).toBeInTheDocument();

    expect(
      screen.getByRole("link", { name: /my requests/i })
    ).toBeInTheDocument();

    expect(
      screen.getByRole("link", { name: /create request/i })
    ).toBeInTheDocument();

    expect(
      await screen.findByRole("link", { name: /all requests/i })
    ).toBeInTheDocument();
  });
});