import React from "react";
import { Check } from "lucide-react";

export interface StepItem {
  id: number;
  title: string;
  description?: string;
}

interface StepWizardProps {
  steps: StepItem[];
  currentStep: number;
  onStepClick?: (step: number) => void;
  children: React.ReactNode;
}

export const StepWizard: React.FC<StepWizardProps> = ({
  steps,
  currentStep,
  children,
}) => {
  return (
    <div style={{ width: "100%" }}>
      {/* Step Indicators */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          marginBottom: "1.75rem",
          padding: "1rem 1.5rem",
          backgroundColor: "#FFFFFF",
          borderRadius: "12px",
          border: "1px solid #E2E8F0",
        }}
      >
        {steps.map((step, idx) => {
          const isCompleted = currentStep > step.id;
          const isActive = currentStep === step.id;

          return (
            <React.Fragment key={step.id}>
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "0.75rem",
                  cursor: "default",
                }}
              >
                <div
                  style={{
                    width: "32px",
                    height: "32px",
                    borderRadius: "50%",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontSize: "0.85rem",
                    fontWeight: 700,
                    transition: "all 0.2s ease",
                    backgroundColor: isCompleted
                      ? "#059669"
                      : isActive
                      ? "#ECFDF5"
                      : "#F1F5F9",
                    color: isCompleted
                      ? "#FFFFFF"
                      : isActive
                      ? "#059669"
                      : "#64748B",
                    border: isActive
                      ? "2px solid #059669"
                      : isCompleted
                      ? "2px solid #059669"
                      : "2px solid #CBD5E1",
                  }}
                >
                  {isCompleted ? <Check size={16} /> : step.id}
                </div>
                <div>
                  <div
                    style={{
                      fontSize: "0.85rem",
                      fontWeight: isActive ? 700 : 600,
                      color: isActive ? "#0F172A" : isCompleted ? "#059669" : "#64748B",
                    }}
                  >
                    {step.title}
                  </div>
                  {step.description && (
                    <div style={{ fontSize: "0.75rem", color: "#94A3B8" }}>
                      {step.description}
                    </div>
                  )}
                </div>
              </div>

              {idx < steps.length - 1 && (
                <div
                  style={{
                    flex: 1,
                    height: "2px",
                    margin: "0 1rem",
                    backgroundColor: currentStep > step.id ? "#059669" : "#E2E8F0",
                    transition: "all 0.3s ease",
                  }}
                />
              )}
            </React.Fragment>
          );
        })}
      </div>

      {/* Step Content */}
      <div className="animate-scale-in">{children}</div>
    </div>
  );
};
