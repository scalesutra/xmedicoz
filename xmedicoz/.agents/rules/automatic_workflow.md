# Automatic Workflow & Implementation Rules

## 1. Autonomous Execution
* Once requirements are understood, proceed automatically end-to-end.
* Do not ask "Should I proceed?", "Shall I start?", or request redundant confirmations.
* Provide a short implementation plan and immediately transition to writing code and executing changes.
* Complete tasks thoroughly, including verification (`flutter analyze`), without unnecessary stopping points.

## 2. Technical Standards
* **State Management**: Use **GetX** (`GetxController`, `Obx`, `Rx`, `Get.put`, `Get.find`).
* **Responsiveness**: Use **Flutter ScreenUtil** (`.w`, `.h`, `.sp`, `.r`).
* **Design System**: Reuse `AppColors`, `AppTypography`, `AppDecorations`, and existing `lib/core/widgets/`.
* **Scope Discipline**: Only modify what is directly necessary; do not touch unrelated code.

## 3. Core Guardrails
* **Confirmation Guardrail**: Plan first, then proceed automatically. Do not repeatedly ask for confirmation.
* **Context Guardrail**: Use conversation context and already established requirements. Never ask the user to re-explain.
* **Decision Guardrail**: Safely infer small details using existing project patterns rather than interrupting the user.

## 4. Strict Zero-Mock & Fallback Policy
* **No Mock / Dummy Data**: Never write hardcoded sample/mock data in controllers, models, or UI sheets.
* **Live or Empty Collections**: All collections must be empty (`<Model>[].obs`) until populated from real APIs or local persistence.
* **Fallbacks**:
  * Empty data -> Branded empty state UI (`EmptyStateWidget`) with action button.
  * Offline -> Real persistent storage cache, never fabricated data.
  * Loading -> Shimmer skeleton / spinner, never demo cards.
  * Missing fields -> Safe null-coalescing defaults (`?? 0.0`, `?? ''`, `?? DateTime.now()`).
* **Document Reference**: See `docs/ZERO_MOCK_AND_FALLBACK_POLICY.md`.

