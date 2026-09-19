import React from "react";
import ReactDOM from "react-dom/client";
import { AuthProvider } from "./context/AuthContext.js";
import { ShopProvider } from "./context/ShopContext.js";
import { ToastProvider } from "./context/ToastContext.js";
import { AppContent } from "./App.js";
import "./theme/theme.css";

const rootElement = document.getElementById("root");

if (rootElement) {
  ReactDOM.createRoot(rootElement).render(
    <React.StrictMode>
      <ToastProvider>
        <AuthProvider>
          <ShopProvider>
            <AppContent />
          </ShopProvider>
        </AuthProvider>
      </ToastProvider>
    </React.StrictMode>
  );
}
