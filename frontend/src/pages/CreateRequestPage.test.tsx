import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { test, expect } from "vitest";
import CreateRequestPage from "./CreateRequestPage";

test("renders the create request form", () => {
  render(
    <MemoryRouter>
      <CreateRequestPage />
    </MemoryRouter>
  );

  expect(
    screen.getByRole("heading", { name: /create service request/i })
  ).toBeInTheDocument();

  expect(screen.getByLabelText(/title/i)).toBeInTheDocument();
  expect(screen.getByLabelText(/description/i)).toBeInTheDocument();
  expect(screen.getByLabelText(/category/i)).toBeInTheDocument();
  expect(screen.getByLabelText(/priority/i)).toBeInTheDocument();

  expect(
    screen.getByRole("button", { name: /create request/i })
  ).toBeInTheDocument();
});