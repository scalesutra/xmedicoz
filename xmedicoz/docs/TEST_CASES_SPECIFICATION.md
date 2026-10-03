# 📋 XMedicoz (Pharma Ledger ERP) - Formal Test Cases Specification Document

**Project Name:** XMedicoz - Medical Ledger & Pharmacy ERP System  
**Document Version:** 1.0.0  
**Prepared For:** Project Submission & Academic / QA Evaluation  
**Status:** Approved / Executed  
**Testing Type:** Manual Functional Testing & Automated Unit/Widget Testing  

---

## 🎯 Executive Summary
Yeh document **XMedicoz** application ke tamam core modules ki testing coverage provide karta hai. Isme har feature ke liye:
- **Test Case ID**
- **Test Scenario / Description**
- **Preconditions**
- **Step-by-Step Test Procedure**
- **Test Data / Inputs**
- **Expected Results**
- **Actual Results**
- **Status (Pass / Fail)**
- **Priority (High / Medium / Low)**

---

## 📊 Test Execution Summary

| Module Name | Total Tests | Passed | Failed | Status |
| :--- | :---: | :---: | :---: | :---: |
| 1. Authentication & Security (AUTH) | 8 | 8 | 0 | ✅ PASS |
| 2. Inventory & Medicine Masters (INV) | 7 | 7 | 0 | ✅ PASS |
| 3. Sales & Counter Billing (SALE) | 8 | 8 | 0 | ✅ PASS |
| 4. Purchases & Stockist Inward (PUR) | 5 | 5 | 0 | ✅ PASS |
| 5. Accounting & Daybook Ledger (ACC) | 6 | 6 | 0 | ✅ PASS |
| 6. Customer & Doctor CRM (CRM) | 4 | 4 | 0 | ✅ PASS |
| 7. Offline Resilience & Sync (NET) | 4 | 4 | 0 | ✅ PASS |
| **Total** | **42** | **42** | **0** | **100% PASS** |

---

## 🧪 Module 1: Authentication & Security (AUTH)

| Test ID | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Status | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-AUTH-01** | Verify Login with valid 10-digit mobile number | App open on Login Screen | 1. Mobile number field me 10 digit number enter karo.<br>2. "Continue" button par tap karo. | Phone: `9876543210` | OTP screen/bottom-sheet open honi chahiye aur OTP send hona chahiye. | **PASS** | High |
| **TC-AUTH-02** | Verify Login with invalid/short mobile number | App open on Login Screen | 1. 5-digit number enter karo.<br>2. "Continue" button tap karo. | Phone: `12345` | Validation error show hona chahiye: "Enter valid 10-digit phone number". Button disable ya error prompt de. | **PASS** | High |
| **TC-AUTH-03** | Verify OTP verification with correct 4-digit OTP | OTP Screen open | 1. Correct 4-digit OTP enter karo.<br>2. Verify button tap karo ya auto-submit ho. | OTP: `4455` | "Verified Successfully" animation display ho aur user Dashboard par redirect ho. | **PASS** | High |
| **TC-AUTH-04** | Verify OTP verification with wrong OTP | OTP Screen open | 1. Wrong 4-digit code enter karo.<br>2. Verify tap karo. | OTP: `0000` | Error snackbar/alert show ho: "Invalid OTP code entered". User screen par hi rahe. | **PASS** | High |
| **TC-AUTH-05** | Verify Resend OTP countdown timer | OTP Screen open | 1. Resend button check karo initial state me.<br>2. 30s countdown khatam hone ka wait karo. | Timer: 30s | Timer chalne tak Resend button disabled rahe, 0s hone par clickable ho. | **PASS** | Medium |
| **TC-AUTH-06** | Verify User Logout and Session Clear | User Dashboard par logged in hai | 1. Profile/Settings me jao.<br>2. "Logout" button press karo.<br>3. Confirm karo. | Action: Logout | User session clear ho, storage wipe ho aur Login Screen show ho. Back button se wapas dashboard na aye. | **PASS** | High |
| **TC-AUTH-07** | Verify Password Login with Email & Password | Login Screen (Password Tab) open | 1. Registered Email/Phone enter karo.<br>2. Password enter karo.<br>3. "Sign In" tap karo. | Identifier: `owner@pharmacy.com`, Pass: `StrongPass@123` | Backend me `{"identifier": "...", "password": "..."}` POST request jaye, JWT tokens cache hon aur Dashboard load ho. | **PASS** | High |
| **TC-AUTH-08** | Verify Pharmacy Registration with Email & Password | Register Pharmacy Screen open | 1. Owner Name, Email, Password, Phone, Shop Name, DL No enter karo.<br>2. "Register Pharmacy" tap karo. | Email: `owner@xmedicoz.com`, Pass: `Pass@2026`, DL: `DL-20B-11` | Backend payload me `email` aur `password` correctly transmit hon aur new pharmacy create ho jaye. | **PASS** | Critical |

---

## 🧪 Module 2: Inventory & Medicine Masters (INV)

| Test ID | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Status | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-INV-01** | Verify Medicine search with full & partial keywords | Inventory screen open | 1. Search bar me text type karo.<br>2. Instant search list observe karo. | Query: `"Pan"` ya `"Paracetamol"` | List instantly filter hokar matching medicines display kare. | **PASS** | High |
| **TC-INV-02** | Verify Adding a new Medicine Master record | Inventory master form open | 1. Name, Generic, Category, Manufacturer enter karo.<br>2. "Save" tap karo. | Name: `Augmentin 625mg`, Cat: `Antibiotics` | New medicine successfully list me add ho aur persistence me save ho. | **PASS** | High |
| **TC-INV-03** | Verify Validation on Medicine Master required fields | Form open | 1. Medicine name empty chhor kar "Save" dabao. | Name: `""` (Empty) | Validation error: "Medicine name is required". Save action block ho. | **PASS** | Medium |
| **TC-INV-04** | Verify Batch creation with Expiry Date and MRP | Medicine detail screen open | 1. "Add Batch" tap karo.<br>2. Batch number, Expiry date, Purchase rate, MRP, Qty enter karo. | Batch: `B-9021`, Exp: `12/2027`, MRP: `150`, Qty: `50` | Batch successfully add ho aur total medicine stock increase ho jaye. | **PASS** | High |
| **TC-INV-05** | Verify Near-Expiry and Expired Medicine alert | Dashboard / Inventory | 1. Aise batch ko check karo jiski expiry next 30 days me hai. | Exp Date: Today + 15 days | Warning badge/amber color "Near Expiry" tag display ho. | **PASS** | High |
| **TC-INV-06** | Verify Zero-stock / Out of stock indicator | Inventory list | 1. Jis item ki quantity 0 hai usko view karo. | Qty: `0` | "Out of Stock" red badge show ho aur billing me warn kare. | **PASS** | Medium |
| **TC-INV-07** | Verify Pagination / Lazy loading of large medicine catalog | Large dataset (e.g. 500+ items) | 1. Inventory list ko scroll down karo. | Page: 1 to 2 | Smooth lazy-load ho, extra pages fetch hon bina UI freeze hue. | **PASS** | Medium |

---

## 🧪 Module 3: Sales & Counter POS Billing (SALE)

| Test ID | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Status | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-SALE-01** | Verify adding item to sales cart | Billing screen open | 1. Searchable dropdown se medicine select karo.<br>2. Batch aur Qty enter karo.<br>3. "Add to Bill" press karo. | Item: `Panadol 500mg`, Qty: `2`, Rate: `30` | Item cart table me appear ho with Subtotal = 60. | **PASS** | High |
| **TC-SALE-02** | Verify automatic calculation of Line Total | Item added in bill | 1. Quantity badhao (e.g. 2 se 5). | Qty: `5`, Unit Price: `30` | Line total automatically `150` calculate ho. | **PASS** | High |
| **TC-SALE-03** | Verify Discount calculation (Flat & Percentage) | Items added in bill | 1. Total Bill par 10% discount apply karo. | Gross: `1000`, Disc%: `10%` | Discount Amount `100` aur Net Payable `900` accurately calculate ho. | **PASS** | High |
| **TC-SALE-04** | Verify Tax / GST calculation | Items added in bill | 1. GST rate select karo (e.g. 18% ya 5%). | Taxable: `1000`, GST: `18%` | Tax amount `180` add hokar Grand Total `1180` ban jaye. | **PASS** | High |
| **TC-SALE-05** | Verify stock deduction after Invoice completion | Medicine stock: 50 | 1. 5 units ka bill create karke "Complete Sale" press karo. | Sold Qty: `5` | Inventory me stock decrease hokar exactly `45` ho jana chahiye. | **PASS** | Critical |
| **TC-SALE-06** | Verify Selling more than available stock error | Medicine stock: 10 | 1. Bill me 15 quantity daalne ki koshish karo. | Requested: `15`, Available: `10` | Error show ho: "Insufficient stock available (Max: 10)". Action block ho. | **PASS** | High |
| **TC-SALE-07** | Verify Payment Modes (Cash, Card, UPI/Online, Credit) | Bill summary screen | 1. Payment mode "Cash" ya "Credit" select karo.<br>2. Submit invoice. | Mode: `Credit`, Customer: `Ahmed` | Credit sale hone par customer ke Ledger balance me debit entry post ho. | **PASS** | High |
| **TC-SALE-08** | Verify Invoice PDF / Receipt generation | Invoice completed | 1. "Print / Share Receipt" button press karo. | Invoice ID: `INV-2026-001` | Formatted receipt open ho with Pharmacy header, items, tax, and total. | **PASS** | Medium |

---

## 🧪 Module 4: Purchases & Stock Inward (PUR)

| Test ID | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Status | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-PUR-01** | Verify Purchase Entry from Supplier/Stockist | Purchase screen open | 1. Supplier select karo.<br>2. Invoice number & date enter karo.<br>3. Items, purchase rate aur batch add karo.<br>4. Save karo. | Supplier: `ABC Pharma`, BillNo: `PB-104`, Qty: `100` | Purchase order save ho aur inventory stock `+100` increase ho. | **PASS** | High |
| **TC-PUR-02** | Verify Supplier Payable Ledger update on credit purchase | Purchase created | 1. Credit par purchase save karo.<br>2. Supplier ledger check karo. | Amount: `50,000` | Supplier account me `50,000` Credit (Payable) entry generate ho. | **PASS** | High |
| **TC-PUR-03** | Verify Purchase Return calculation | Purchase history open | 1. Damaged item ke 5 units return mark karo. | Return Qty: `5`, Rate: `100` | Stock `-5` ho aur supplier payable se `500` minus/debit ho. | **PASS** | Medium |
| **TC-PUR-04** | Verify Duplicate Purchase Bill No warning | Existing bill PB-104 | 1. Same supplier aur same bill number dobara enter karo. | BillNo: `PB-104` | Warning: "Invoice number already exists for this supplier". | **PASS** | Medium |
| **TC-PUR-05** | Verify Purchase Cost vs MRP validation | Purchase entry form | 1. Purchase cost MRP se zyada daalo. | Cost: `200`, MRP: `150` | Warning prompt: "Purchase rate cannot exceed MRP". | **PASS** | Low |

---

## 🧪 Module 5: Accounting, Daybook & Ledger (ACC)

| Test ID | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Status | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-ACC-01** | Verify Daily Cashbook / Daybook entries | Daybook screen open | 1. Aaj ke din ki tamam cash in & cash out check karo. | Date: Today | Total Cash Sales, Cash Expenses, aur Closing Cash balance tally ho. | **PASS** | High |
| **TC-ACC-02** | Verify Double-entry ledger balance (Debit = Credit) | Voucher screen open | 1. Payment voucher create karo (Supplier payment). | Debit: `Supplier A (5000)`, Credit: `Bank (5000)` | Journal voucher balanced save ho; dono sides equal rahein. | **PASS** | Critical |
| **TC-ACC-03** | Verify Customer Ledger balance statement | Customer profile open | 1. Customer statement view karo. | Customer ID: `CUST-01` | Invoices (+Debit) aur Payments (-Credit) ke baad net balance accurate ho. | **PASS** | High |
| **TC-ACC-04** | Verify Expense Voucher recording | Expense screen open | 1. Category select karo (e.g. Electricity, Tea).<br>2. Amount enter karke pay karo. | Category: `Utilities`, Amount: `1500` | Expense daybook me record ho aur net daily profit se deduct ho. | **PASS** | Medium |
| **TC-ACC-05** | Verify Date Range filter on Ledger | Ledger report open | 1. "From Date" aur "To Date" choose karo.<br>2. "Filter" tap karo. | Range: `01/01/2026` to `31/01/2026` | Sirf selected date range ke transactions display hon with opening balance. | **PASS** | Medium |
| **TC-ACC-06** | Verify Export Ledger to PDF / CSV | Ledger screen open | 1. "Export Report" button press karo. | Format: PDF | Well-formatted PDF file generate ho jisme running balance show ho. | **PASS** | Low |

---

## 🧪 Module 6: Customer Relationship & CRM (CRM)

| Test ID | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Status | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-CRM-01** | Verify Create new Customer with credit limit | Customer list open | 1. "Add Customer" press karo.<br>2. Name, Phone, Address, Credit limit enter karo.<br>3. Save. | Name: `Ali Khan`, Phone: `03001234567`, Limit: `25,000` | Customer create ho aur list me show ho. | **PASS** | High |
| **TC-CRM-02** | Verify Exceeding Customer Credit Limit Alert | Customer has limit: 10,000 | 1. 15,000 ka credit bill banayein. | Bill: `15,000`, Limit: `10,000` | Alert prompt: "Credit limit exceeded by 5,000. Approval required". | **PASS** | High |
| **TC-CRM-03** | Verify Doctor Master entry & Commission Tagging | Doctor screen open | 1. Doctor name, hospital & specialization save karo. | Dr. Farhan, MBBS | Invoicing ke waqt doctor referral dropdown me name show ho. | **PASS** | Medium |
| **TC-CRM-04** | Verify Search customer by name or phone | CRM list open | 1. Phone number ke last 4 digits enter karo. | Query: `"4567"` | Matching customer instant filter ho jaye. | **PASS** | Medium |

---

## 🧪 Module 7: Offline Resilience & Connectivity (NET)

| Test ID | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Status | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-NET-01** | Verify Offline Banner appears on network disconnection | App running online | 1. Wi-Fi & Mobile data turn OFF karo. | Network: Offline | Top par non-intrusive "Offline Mode - Changes saved locally" badge show ho. | **PASS** | High |
| **TC-NET-02** | Verify Local persistence in offline state | Device is offline | 1. Local storage me new draft bill banayein. | Draft Bill | Bill local storage (Hive/SQLite) me bina crash ke save ho. | **PASS** | High |
| **TC-NET-03** | Verify Auto-reconnect & banner dismiss | Device offline hai | 1. Wi-Fi / Data turn ON karo. | Network: Online | Offline banner smoothly slide out ho aur sync indicator trigger ho. | **PASS** | Medium |
| **TC-NET-04** | Verify Zero-Mock fallback policy on empty API responses | API returns empty array | 1. Empty catalog / parties load karo. | Response: `[]` | No fake/mock data show ho; clean cyber empty-state illustration display ho. | **PASS** | High |

---

## 🤖 Automated Flutter Unit & Widget Test Cases
Is project ke codebase me automated tests already maujood hain jo automated pipeline me verify hote hain:

1. **`test/widget_test.dart`**: App launch smoke test with ScreenUtil initialization.
2. **`test/otp_v7_test.dart`**: OTP bottom-sheet rendering, digit input controllers, interactive animation flow, and success message verification.
3. **`test/medicine_choices_test.dart`**: Multi-page pagination, cache reuse, concurrency handling, invalidation on medicine registration, and supplier choice filters.
4. **`test/smart_search_test.dart`**: Search algorithms, substring matching, debouncing, and filter accuracy.
5. **`test/searchable_medicine_dropdown_test.dart`**: Dynamic autocomplete dropdown widget interaction, keyboard navigation, and selection handlers.

### Test Execution Command:
```bash
flutter test
```
*Expected Output:* `All tests passed!`
