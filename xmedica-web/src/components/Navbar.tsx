import React, { useState, useEffect } from "react";
import { Plus, Menu, X, ArrowUpRight } from "lucide-react";
import { AppColors } from "../theme/colors";
import { AppConfig } from "../config/appConfig";

interface NavbarProps {
  onOpenPlayStoreModal: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ onOpenPlayStoreModal }) => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const navLinks = [
    { label: "Modules", href: "#features" },
    { label: "App Simulator", href: "#showcase" },
    { label: "Google Play", href: "#playstore" },
    { label: "Plans", href: "#pricing" },
    { label: "Compliance", href: "#compliance" },
    { label: "FAQ", href: "#faq" },
  ];

  const handleNavClick = (href: string) => {
    setIsMobileMenuOpen(false);
    const element = document.querySelector(href);
    if (element) {
      element.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <>
      <header
        style={{
          position: "fixed",
          top: 0,
          left: 0,
          right: 0,
          zIndex: 100,
          transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
          backgroundColor: isScrolled
            ? "rgba(255, 255, 255, 0.94)"
            : "rgba(248, 250, 249, 0.88)",
          backdropFilter: "blur(18px)",
          WebkitBackdropFilter: "blur(18px)",
          borderBottom: `1px solid ${isScrolled ? AppColors.borderSubtle : "transparent"}`,
          boxShadow: isScrolled ? "0 4px 24px -2px rgba(15, 23, 42, 0.05)" : "none",
        }}
      >
        <div
          className="container-custom"
          style={{
            height: "72px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            gap: "0.75rem",
          }}
        >
          {/* Brand Logo */}
          <a
            href="#"
            style={{
              display: "flex",
              alignItems: "center",
              gap: "0.65rem",
              textDecoration: "none",
              flexShrink: 0,
            }}
          >
            <div
              style={{
                width: "36px",
                height: "36px",
                borderRadius: "10px",
                background: `linear-gradient(135deg, ${AppColors.primaryEmerald} 0%, ${AppColors.deepTeal} 100%)`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#FFFFFF",
                boxShadow: "0 6px 14px -2px rgba(5, 150, 105, 0.35)",
              }}
            >
              <Plus size={20} strokeWidth={3.5} />
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: "0.4rem" }}>
              <span
                style={{
                  fontSize: "1.25rem",
                  fontWeight: 800,
                  letterSpacing: "-0.03em",
                  color: AppColors.textPrimary,
                }}
              >
                X Medica
              </span>
              <span
                style={{
                  fontSize: "0.65rem",
                  fontWeight: 700,
                  padding: "1px 6px",
                  borderRadius: "5px",
                  backgroundColor: AppColors.tealSurface,
                  color: AppColors.deepTeal,
                  border: `1px solid ${AppColors.emeraldLight}35`,
                  letterSpacing: "0.04em",
                }}
              >
                OS
              </span>
            </div>
          </a>

          {/* Center Navigation Links (Clean Single-Line, Desktop Only) */}
          <nav
            style={{
              display: "none",
              alignItems: "center",
              gap: "1.8rem",
            }}
            className="desktop-nav"
          >
            {navLinks.map((link) => (
              <a
                key={link.label}
                href={link.href}
                onClick={(e) => {
                  e.preventDefault();
                  handleNavClick(link.href);
                }}
                style={{
                  fontSize: "0.88rem",
                  fontWeight: 600,
                  color: AppColors.textSecondary,
                  transition: "all 0.15s ease",
                  padding: "4px 2px",
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.color = AppColors.primaryEmerald;
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.color = AppColors.textSecondary;
                }}
              >
                {link.label}
              </a>
            ))}
          </nav>

          {/* Desktop Right Action Buttons */}
          <div
            style={{
              display: "none",
              alignItems: "center",
              gap: "0.75rem",
              flexShrink: 0,
            }}
            className="desktop-actions"
          >
            {/* Google Play Button */}
            <button
              onClick={onOpenPlayStoreModal}
              style={{
                display: "flex",
                alignItems: "center",
                gap: "0.45rem",
                padding: "0.55rem 1rem",
                borderRadius: "10px",
                backgroundColor: AppColors.bgSidebar,
                color: "#FFFFFF",
                fontSize: "0.84rem",
                fontWeight: 600,
                border: "1px solid rgba(255, 255, 255, 0.12)",
                boxShadow: "0 2px 8px rgba(11, 25, 23, 0.15)",
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = AppColors.bgCardDark;
                e.currentTarget.style.transform = "translateY(-1px)";
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = AppColors.bgSidebar;
                e.currentTarget.style.transform = "none";
              }}
            >
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none">
                <path d="M3.6 1.8L14.4 12L3.6 22.2C3.2 21.7 3 21 3 20.2V3.8C3 3 3.2 2.3 3.6 1.8Z" fill="#00C3FF" />
                <path d="M17.9 8.6L14.4 12L17.9 15.4L21.3 13.5C22.3 12.9 22.3 11.1 21.3 10.5L17.9 8.6Z" fill="#FFD400" />
                <path d="M14.4 12L3.6 1.8C4.1 1.3 4.9 1.1 5.8 1.6L17.9 8.6L14.4 12Z" fill="#00E676" />
                <path d="M14.4 12L17.9 15.4L5.8 22.4C4.9 22.9 4.1 22.7 3.6 22.2L14.4 12Z" fill="#FF334B" />
              </svg>
              <span>Google Play</span>
            </button>

            {/* Launch Web App Button - Direct link to real web app */}
            <a
              href={AppConfig.webAppUrl}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: "flex",
                alignItems: "center",
                gap: "0.35rem",
                padding: "0.55rem 1.1rem",
                borderRadius: "10px",
                backgroundColor: AppColors.primaryEmerald,
                color: "#FFFFFF",
                fontSize: "0.84rem",
                fontWeight: 700,
                boxShadow: "0 4px 14px -2px rgba(5, 150, 105, 0.35)",
                textDecoration: "none",
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = AppColors.primaryEmeraldHover;
                e.currentTarget.style.transform = "translateY(-1px)";
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = AppColors.primaryEmerald;
                e.currentTarget.style.transform = "none";
              }}
            >
              <span>Launch Web App</span>
              <ArrowUpRight size={15} />
            </a>
          </div>

          {/* Mobile Hamburger Button */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            aria-label="Toggle Navigation"
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              width: "38px",
              height: "38px",
              borderRadius: "8px",
              backgroundColor: AppColors.white,
              border: `1px solid ${AppColors.borderSubtle}`,
              color: AppColors.textPrimary,
            }}
            className="mobile-toggle"
          >
            {isMobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
      </header>

      {/* Mobile Menu Drawer */}
      {isMobileMenuOpen && (
        <div
          style={{
            position: "fixed",
            top: "72px",
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: "rgba(15, 23, 42, 0.45)",
            backdropFilter: "blur(8px)",
            zIndex: 99,
          }}
          onClick={() => setIsMobileMenuOpen(false)}
        >
          <div
            style={{
              backgroundColor: AppColors.white,
              padding: "1.25rem",
              borderBottom: `1px solid ${AppColors.borderSubtle}`,
              boxShadow: "0 16px 32px rgba(0,0,0,0.12)",
              display: "flex",
              flexDirection: "column",
              gap: "0.85rem",
              maxHeight: "calc(100vh - 80px)",
              overflowY: "auto",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem" }}>
              {navLinks.map((link) => (
                <a
                  key={link.label}
                  href={link.href}
                  onClick={(e) => {
                    e.preventDefault();
                    handleNavClick(link.href);
                  }}
                  style={{
                    fontSize: "1rem",
                    fontWeight: 600,
                    color: AppColors.textPrimary,
                    padding: "0.5rem 0",
                    borderBottom: `1px solid ${AppColors.frostMint}`,
                  }}
                >
                  {link.label}
                </a>
              ))}
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "0.65rem", marginTop: "0.5rem" }}>
              <button
                onClick={() => {
                  setIsMobileMenuOpen(false);
                  onOpenPlayStoreModal();
                }}
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "0.5rem",
                  padding: "0.8rem",
                  borderRadius: "10px",
                  backgroundColor: AppColors.bgSidebar,
                  color: "#FFFFFF",
                  fontWeight: 600,
                  fontSize: "0.92rem",
                }}
              >
                <span>Get on Google Play</span>
              </button>

              <a
                href={AppConfig.webAppUrl}
                target="_blank"
                rel="noopener noreferrer"
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "0.4rem",
                  padding: "0.8rem",
                  borderRadius: "10px",
                  backgroundColor: AppColors.primaryEmerald,
                  color: "#FFFFFF",
                  fontWeight: 700,
                  fontSize: "0.92rem",
                  textDecoration: "none",
                }}
              >
                <span>Launch Web App (Port 5096)</span>
                <ArrowUpRight size={16} />
              </a>
            </div>
          </div>
        </div>
      )}

      <style>{`
        @media (min-width: 960px) {
          .desktop-nav {
            display: flex !important;
          }
          .desktop-actions {
            display: flex !important;
          }
          .mobile-toggle {
            display: none !important;
          }
        }
      `}</style>
    </>
  );
};
