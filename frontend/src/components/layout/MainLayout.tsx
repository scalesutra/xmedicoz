import React, { useState, useEffect } from "react";
import { Sidebar, NavTab } from "./Sidebar.js";
import { Topbar } from "./Topbar.js";

interface MainLayoutProps {
  currentTab: NavTab;
  onSelectTab: (tab: NavTab) => void;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}

export const MainLayout: React.FC<MainLayoutProps> = ({
  currentTab,
  onSelectTab,
  title,
  subtitle,
  children,
}) => {
  const [isMobile, setIsMobile] = useState<boolean>(() => {
    if (typeof window !== "undefined") {
      return window.innerWidth < 768;
    }
    return false;
  });

  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState<boolean>(false);

  // Collapse desktop sidebar by default on screens < 1200px
  const [isCollapsed, setIsCollapsed] = useState<boolean>(() => {
    if (typeof window !== "undefined") {
      return window.innerWidth < 1200;
    }
    return false;
  });

  useEffect(() => {
    const handleResize = () => {
      const mobile = window.innerWidth < 768;
      setIsMobile(mobile);
      if (!mobile && isMobileSidebarOpen) {
        setIsMobileSidebarOpen(false);
      }
      if (window.innerWidth < 1080 && !isCollapsed) {
        setIsCollapsed(true);
      }
    };
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, [isCollapsed, isMobileSidebarOpen]);

  const toggleSidebar = () => {
    if (isMobile) {
      setIsMobileSidebarOpen((prev) => !prev);
    } else {
      setIsCollapsed((prev) => !prev);
    }
  };

  return (
    <div style={{ display: "flex", minHeight: "100vh", backgroundColor: "#F3F6F5", position: "relative" }}>
      <Sidebar
        currentTab={currentTab}
        onSelectTab={(tab) => {
          onSelectTab(tab);
          if (isMobile) {
            setIsMobileSidebarOpen(false);
          }
        }}
        collapsed={isCollapsed}
        onToggleCollapse={toggleSidebar}
        isMobile={isMobile}
        mobileOpen={isMobileSidebarOpen}
        onCloseMobile={() => setIsMobileSidebarOpen(false)}
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
        <Topbar
          title={title}
          subtitle={subtitle}
          isSidebarCollapsed={isMobile ? !isMobileSidebarOpen : isCollapsed}
          onToggleSidebar={toggleSidebar}
          onSelectTab={onSelectTab}
          isMobile={isMobile}
        />
        <main
          style={{
            flex: 1,
            backgroundColor: "#FFFFFF",
            overflowY: "auto",
            overflowX: "hidden",
            display: "flex",
            flexDirection: "column",
            WebkitOverflowScrolling: "touch",
          }}
        >
          {children}
        </main>
      </div>
    </div>
  );
};
