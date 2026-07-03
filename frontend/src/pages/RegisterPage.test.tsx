import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { test, expect } from "vitest";
import RegisterPage from "./RegisterPage";

test("renders the register page", () => {
  render(
    <MemoryRouter>
      <RegisterPage />
    </MemoryRouter>
  );

  expect(
    screen.getByRole("heading", { name: /create account/i })
  ).toBeInTheDocument();

  expect(screen.getByLabelText(/name/i)).toBeInTheDocument();
  expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
  expect(screen.getByLabelText(/password/i)).toBeInTheDocument();

  expect(
    screen.getByRole("button", { name: /register/i })
  ).toBeInTheDocument();
});