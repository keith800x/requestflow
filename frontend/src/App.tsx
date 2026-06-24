import { BrowserRouter, Routes, Route } from "react-router-dom";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";
import DashboardPage from "./pages/DashboardPage";
import MyRequestsPage from "./pages/MyRequestsPage";
import CreateRequestPage from "./pages/CreateRequestPage";
import AdminRequestsPage from "./pages/AdminRequestsPage";
import RequestDetailPage from "./pages/RequestDetailPage";

import ProtectedRoute from "./components/ProtectedRoute";
import AdminRoute from "./components/AdminRoute";
import AppLayout from "./components/AppLayout";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Public pages */}
        <Route path="/" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />

        {/* Logged-in pages with shared layout */}
        <Route element={<ProtectedRoute />}>
          <Route element={<AppLayout />}>
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/requests" element={<MyRequestsPage />} />
            <Route path="/requests/new" element={<CreateRequestPage />} />
            <Route path="/requests/:requestId" element={<RequestDetailPage />} />

            {/* Admin-only pages */}
            <Route element={<AdminRoute />}>
              <Route path="/admin/requests" element={<AdminRequestsPage />} />
            </Route>
          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  );
}