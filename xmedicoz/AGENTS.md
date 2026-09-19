# AGENTS.md - Antigravity Agent Guidelines & Automatic Workflow Rules

## 1. Automatic Work Rule
* **Autonomous Execution**: Once the requirement is clear, proceed with the work automatically end-to-end.
* **No Unnecessary Confirmation Loops**:
  * Do NOT repeatedly ask the user to confirm the same requirement.
  * Do NOT ask *"Should I start?"* or *"Shall I proceed?"* after providing the implementation plan.
  * Do NOT ask for approval at every small intermediate step.
  * Do NOT repeat questions that have already been answered.
* **Context Preservation**: Strictly remember and use previous conversation context, architectural decisions, and previously stated requirements.
* **Direct Execution**: After presenting a short, concise implementation plan, continue directly with the implementation.
* **Autonomous Decision Making**:
  * Make reasonable decisions based on existing project patterns, themes, and guardrails.
  * If a small detail is unclear but can be safely inferred from existing code, follow the existing pattern instead of interrupting the user.
  * Ask a question ONLY when a genuinely critical piece of information is completely missing and the task cannot be safely completed without it.
* **End-to-End Delivery**: Complete the requested task from code implementation through to verification (e.g. running `flutter analyze`) without stopping midway.

---

## 2. Standard Working Flow

1. **Requirement Received**: Read and fully understand the user's intent.
2. **Context & Codebase Check**: Inspect existing project code, models, controllers, and reusable widgets (`lib/core`).
3. **Short Implementation Plan**: Outline a brief, actionable plan summarizing files to change and approach.
4. **Immediate Implementation**: Proceed directly with code changes without asking for permission.
5. **Architectural Guardrails**:
   * **State Management**: Strictly use **GetX** (`GetxController`, `Get.find`, `Obx`, `Rx`).
   * **Responsive Design**: Strictly use **Flutter ScreenUtil** (`.w`, `.h`, `.sp`, `.r`).
   * **Design Tokens & Theme**: Reuse centralized tokens in `lib/core/theme/`:
     * Colors: `AppColors` (e.g., `AppColors.primaryEmerald`, `AppColors.bgSurface`, etc.)
     * Typography: `AppTypography`
     * Decorations: `AppDecorations`
   * **Reusable UI**: Reuse common widgets in `lib/core/widgets/` (e.g. `AppButton`, `AppTextField`, `AppBackground`, `UniqueCyberNavBar`, etc.).
6. **Surgical Precision**:
   * Make only the required changes.
   * Do NOT modify unrelated code or break existing features.
7. **Verification**: Verify functionality and run code analysis (`flutter analyze`) to ensure zero errors.
8. **Summary**: Provide a concise summary of what was accomplished without asking for repeated confirmations.

---

## 3. Core Guardrails

### 🛡️ Confirmation Guardrail
> **Plan first, then proceed automatically.**
> Do not pause or repeatedly ask for user permission to continue.

### 🧠 Context Guardrail
> **Remember and use requirements already provided in the conversation.**
> Do not ask the user to explain the same requirement again.

### ⚖️ Decision Guardrail
> **When a minor implementation decision is needed, follow existing project conventions and pick the cleanest, simplest solution instead of interrupting the user.**

---

## 4. Strict Zero-Mock Data & Fallback Policy
* **Zero Mock Mandate**:
  * Absolutely NO hardcoded mock, synthetic, or dummy data anywhere in controllers, repositories, services, or UI components.
  * All collections (`medicines`, `customers`, `parties`, `transactions`, `refills`) must initialize as empty (`<Model>[].obs`) and be populated solely through real REST/GraphQL APIs or local persistent storage.
  * Never fabricate mock fallback arrays in `catch` blocks or offline scenarios.
* **Standardized Fallback Behavior**:
  * **Empty State**: When any collection is empty (`isEmpty`), display a clean, branded cyber-medical empty state widget with an icon, explanatory subtitle, and a primary CTA button (e.g. *"Create First Invoice"*).
  * **Offline/Network Issue**: Rely strictly on persistent local storage (`StorageService` / SQLite / Hive) and display a non-intrusive offline badge. Never inject fake records.
  * **Loading State**: Use skeleton shimmer or `CircularProgressIndicator`, never placeholder demo items.
  * **Missing Fields**: Always use safe null-coalescing defaults (`?? 0.0`, `?? ''`, `?? DateTime.now()`, `?? []`).
* **Specification Document**:
  * Refer to [ZERO_MOCK_AND_FALLBACK_POLICY.md](file:///d:/flutter%20projects/ledger_app/docs/ZERO_MOCK_AND_FALLBACK_POLICY.md) for detailed architecture and component standards.

