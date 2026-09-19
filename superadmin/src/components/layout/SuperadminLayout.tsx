import React, { useState, useEffect } from "react";
import { SuperadminSidebar, SuperadminTab } from "./SuperadminSidebar.js";
import { SuperadminTopbar } from "./SuperadminTopbar.js";

interface LayoutProps {
  currentTab: SuperadminTab;
  onSelectTab: (tab: SuperadminTab) => void;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  onRefreshCurrentTab?: () => void;
}

export const SuperadminLayout: React.FC<LayoutProps> = ({
  currentTab,
  onSelectTab,
  title,
  subtitle,
  children,
  onRefreshCurrentTab,
}) => {
  const [isMobile, setIsMobile] = useState<boolean>(() => {
    if (typeof window !== "undefined") {
      return window.innerWidth < 768;
    }
    return false;
  });

  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);
  const [isCollapsed, setIsCollapsed] = useState(false);

  useEffect(() => {
    const handleResize = () => {
      const mobile = window.innerWidth < 768;
      setIsMobile(mobile);
      if (!mobile) {
        setMobileSidebarOpen(false);
      }
    };
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  return (
    <div
      style={{
        display: "flex",
        width: "100%",
        minHeight: "100vh",
        backgroundColor: "#0B0F17",
        color: "#F8FAFC",
        position: "relative",
      }}
    >
      <SuperadminSidebar
        currentTab={currentTab}
        onSelectTab={onSelectTab}
        collapsed={isCollapsed}
        onToggleCollapse={() => setIsCollapsed(!isCollapsed)}
        isMobile={isMobile}
        mobileOpen={mobileSidebarOpen}
        onCloseMobile={() => setMobileSidebarOpen(false)}
      />

      <div
        style={{
          flex: 1,
          display: "flex",
          flexDirection: "column",
          minWidth: 0,
          width: "100%",
          height: "100vh",
          overflowX: "hidden",
        }}
      >
        <SuperadminTopbar
          title={title}
          subtitle={subtitle}
          onToggleMobileSidebar={() => setMobileSidebarOpen(!mobileSidebarOpen)}
          isMobile={isMobile}
          onRefreshCurrentTab={onRefreshCurrentTab}
        />

        <main
          style={{
            flex: 1,
            overflowY: "auto",
            overflowX: "hidden",
            padding: isMobile ? "1rem" : "1.75rem 2rem",
            WebkitOverflowScrolling: "touch",
            display: "flex",
            flexDirection: "column",
            gap: "1.5rem",
          }}
        >
          {children}
        </main>
      </div>
    </div>
  );
};
