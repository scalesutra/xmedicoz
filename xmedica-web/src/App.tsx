import React, { useState, useEffect } from "react";
import { Navbar } from "./components/Navbar";
import { HeroSection } from "./components/HeroSection";
import { DeviceShowcase } from "./components/DeviceShowcase";
import { FeaturesSection } from "./components/FeaturesSection";
import { PlayStoreBanner } from "./components/PlayStoreBanner";
import { ComplianceSection } from "./components/ComplianceSection";
import { PricingSection } from "./components/PricingSection";
import { TestimonialsSection } from "./components/TestimonialsSection";
import { FaqSection } from "./components/FaqSection";
import { Footer } from "./components/Footer";
import { PlayStoreModal } from "./components/PlayStoreModal";
import { LegalModal, LegalDocType } from "./components/LegalModal";

export const App: React.FC = () => {
  const [isPlayStoreModalOpen, setIsPlayStoreModalOpen] = useState(false);
  const [isLegalModalOpen, setIsLegalModalOpen] = useState(false);
  const [legalDocType, setLegalDocType] = useState<LegalDocType>("privacy");

  // Handle URL hashes for Google Play Reviewers (e.g. #privacy, #delete-account, #terms)
  useEffect(() => {
    const handleHash = () => {
      const hash = window.location.hash.toLowerCase();
      if (hash === "#privacy") {
        setLegalDocType("privacy");
        setIsLegalModalOpen(true);
      } else if (hash === "#delete-account" || hash === "#delete") {
        setLegalDocType("delete-account");
        setIsLegalModalOpen(true);
      } else if (hash === "#terms") {
        setLegalDocType("terms");
        setIsLegalModalOpen(true);
      } else if (hash === "#refund") {
        setLegalDocType("refund");
        setIsLegalModalOpen(true);
      } else if (hash === "#grievance") {
        setLegalDocType("grievance");
        setIsLegalModalOpen(true);
      }
    };

    handleHash();
    window.addEventListener("hashchange", handleHash);
    return () => window.removeEventListener("hashchange", handleHash);
  }, []);

  const handleOpenLegal = (type: LegalDocType) => {
    setLegalDocType(type);
    setIsLegalModalOpen(true);
  };

  const scrollToSection = (id: string) => {
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <div style={{ minHeight: "100vh", display: "flex", flexDirection: "column" }}>
      {/* Navigation */}
      <Navbar
        onOpenPlayStoreModal={() => setIsPlayStoreModalOpen(true)}
      />

      {/* Main Page Content */}
      <main style={{ flex: 1 }}>
        <HeroSection
          onOpenPlayStoreModal={() => setIsPlayStoreModalOpen(true)}
          onScrollToShowcase={() => scrollToSection("showcase")}
        />

        <DeviceShowcase
          onOpenPlayStoreModal={() => setIsPlayStoreModalOpen(true)}
        />

        <FeaturesSection
          onOpenPlayStoreModal={() => setIsPlayStoreModalOpen(true)}
        />

        <PlayStoreBanner
          onOpenPlayStoreModal={() => setIsPlayStoreModalOpen(true)}
        />

        <ComplianceSection />

        <PricingSection />

        <TestimonialsSection />

        <FaqSection />
      </main>

      {/* Footer */}
      <Footer
        onOpenPlayStoreModal={() => setIsPlayStoreModalOpen(true)}
        onOpenLegalModal={handleOpenLegal}
      />

      {/* Official Google Play Modal */}
      <PlayStoreModal
        isOpen={isPlayStoreModalOpen}
        onClose={() => setIsPlayStoreModalOpen(false)}
      />

      {/* Google Play Mandatory Compliance & Policies Modal */}
      <LegalModal
        isOpen={isLegalModalOpen}
        docType={legalDocType}
        onClose={() => setIsLegalModalOpen(false)}
        onSelectDoc={setLegalDocType}
      />
    </div>
  );
};

export default App;
