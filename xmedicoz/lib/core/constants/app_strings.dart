/// Centralized App Strings for 100% DRY text management across the app.
/// Completely specialized for Medical Stores, Chemists & Pharmacies (XMedicoz).
class AppStrings {
  // App Branding
  static const String appName = 'XMedicoz';
  static const String appTagline =
      'Autonomous Medical Store & Pharmacy Ledger ERP';
  static const String appVersion = 'v2.4 Rx Enterprise';

  // Splash & Onboarding
  static const String welcomeTitle = 'Smart Chemist & Pharmacy ERP Ledger';
  static const String welcomeSubtitle =
      'Manage Batch & Expiry, Salt Formulations, Doctor Prescriptions & Stockists with clinical precision.';
  static const String getStarted = 'Enter Pharmacy Workspace';
  static const String secureCloudBackup =
      '100% Secure • Drug License & GST Compliant • Multi-Counter Sync';

  // Authentication
  static const String loginTitle = 'Login with Mobile';
  static const String loginSubtitle =
      'Enter your 10-digit registered mobile number to access your pharmacy accounts.';
  static const String phoneHint = 'Mobile Number';
  static const String phonePrefix = '+91';
  static const String sendOtp = 'Get Verification Code';
  static const String signUpTitle = 'Register Pharmacy / Chemist';
  static const String signUpSubtitle =
      'Setup your next-gen medical store ledger with batch & expiry tracking.';
  static const String fullNameHint = 'Pharmacist / Proprietor Name';
  static const String businessNameHint = 'Medical Store / Pharmacy Name';
  static const String createAccountBtn = 'Create Pharmacy Account';
  static const String haveAccountPrompt = 'Already registered? ';
  static const String loginNow = 'Login Here';
  static const String noAccountPrompt = "New pharmacy store? ";
  static const String signUpNow = 'Register New Chemist';
  static const String referralCodeHint = 'Referral Code (Optional)';
  static const String selectCategoryLabel = 'Select Pharmacy Store Type:';
  static const String otpTitle = 'Verify Mobile Number';
  static const String otpSubtitle = 'Enter the 4-digit code sent to';
  static const String verifyOtp = 'Verify & Open Medical Store';
  static const String resendOtp = 'Resend Code in';
  static const String resendNow = 'Resend Code Now';
  static const String otpVerifiedSuccess = 'Verified Successfully!';
  static const String otpEnteringWorkspace =
      'Redirecting to pharmacy ledger...';
  static const String otpAutoFillDemo = 'Auto-fill SMS Code (7492)';
  static const String otpInvalidCode =
      'Invalid code. Enter 7492 or any 4 digits.';
  static const String changePhone = 'Change';
  static const String otpVersionBadge = 'PHARMA OTP SECURE V7';
  static const String otpV7TopTitle = 'Pharma OTP Verification';
  static const String otpV7TopVersion = 'V7';
  static const String otpV7Title = "Verify Pharmacist Mobile";
  static const String otpV7Subtitle =
      "We've sent a 4-digit code to your phone.\nIt'll auto-verify once entered.";
  static const String otpV7SuccessTitle = 'Store Verified Successfully';
  static const String otpV7SuccessSubtitle =
      'Your pharmacy account is now active.';
  static const String otpV7VerifiedAndSecure =
      'Verified & Drug License Protected';
  static const String otpV7DidntReceive = "Didn't receive the code? ";
  static const String otpV7Resend = 'Resend';
  static const String termsNotice =
      'By continuing, you agree to Healthcare Data Privacy & Drug Dispensing Policies.';

  // Business Category Selection
  static const String selectBusinessType = 'Select Pharmacy Type';
  static const String selectBusinessTypeSub =
      'We will tailor your medicine batches, schedule registers & HSN tax rates automatically.';
  static const String addShopTitle = 'Register Your Pharmacy';
  static const String addShopSubtitle =
      'Setup your pharmacy profile with Drug License (DL No.) & optional GSTIN.';
  static const String shopNameHint = 'Medical Store / Chemist Trade Name';
  static const String shopOwnerHint = 'Registered Pharmacist / Owner Name';
  static const String shopPhoneHint = 'Pharmacy Contact Number';
  static const String shopCityHint = 'City & Area (e.g. Bandra West, Mumbai)';
  static const String dlNumberHint = 'Drug License No. (e.g. DL-20B/21B-4491)';
  static const String gstinOptional = 'GSTIN (Optional)';
  static const String gstinHelper =
      'Leave blank if you are a non-GST composition or unregistered chemist.';
  static const String createShopButton = 'Launch Pharmacy Workspace';

  // Dashboard & Financial Cockpit
  static const String switchShop = 'Switch Medical Branch';
  static const String liveSync = 'Drug Database Online';
  static const String netSales = 'Net Medicine Sales';
  static const String netPurchases = 'Stockist Purchases';
  static const String grossProfit = 'Gross Margin';
  static const String totalStockValue = 'Stock Valuation';
  static const String cashInHand = 'Counter Cash in Hand';
  static const String bankAccounts = 'Bank Accounts';
  static const String cashInflow = 'Cash Inflow';
  static const String cashOutflow = 'Cash Outflow';
  static const String kitnaAaya = cashInflow;
  static const String kitnaGya = cashOutflow;
  static const String toReceive = 'Total Receivables';
  static const String toPay = 'Total Payables';
  static const String todaySummary = "Today's Financial Pulse";
  static const String quickActions = 'Quick Actions';
  static const String lowStockAlert = 'Critical Medicines & Expiry Alert';
  static const String recentTransactions = 'Recent Transactions & Daybook';
  static const String viewAll = 'View All';

  // Payment Modes
  static const String paymentModeCash = 'Cash';
  static const String paymentModeOnline = 'Online / UPI';
  static const String paymentModeBank = 'Bank Transfer / Cheque';

  // Medicine Inventory & Stock
  static const String inventoryTitle = 'Stock & Batches';
  static const String searchInventoryHint = 'Search medicines...';
  static const String allCategories = 'All Medicines';
  static const String addNewItem = 'Add Medicine / Drug';
  static const String stockQuantity = 'In Stock';
  static const String rackShelf = 'Rack / Cold Storage';
  static const String purchasePrice = 'Purchase Rate';
  static const String wholesalePrice = 'Purchase Rate';
  static const String retailPrice = 'Retail MRP';
  static const String lowStockBadge = 'Re-order Soon';
  static const String nearExpiryBadge = 'Near Expiry (< 60 Days)';
  static const String expiredBadge = 'EXPIRED - RETURN';
  static const String stockIn = '+ Stock Inward';
  static const String stockOut = '- Stock Out';

  // Parties & Ledger (Customers & Suppliers)
  static const String ledgerTitle = 'Accounts & Ledger';
  static const String searchPartiesHint = 'Search parties...';
  static const String customersTab = 'Customers';
  static const String suppliersTab = 'Suppliers';
  static const String addNewParty = '+ Add Account / Party';
  static const String partyStatement = 'Account Statement';
  static const String whatsappReminder = 'Send Payment Reminder';
  static const String settlePayment = 'Settle Account';
  static const String overdueDays = 'days overdue';

  // Vouchers & Daybook
  static const String vouchersTitle = 'Invoices & Daybook';
  static const String searchVouchersHint = 'Search invoices...';
  static const String saleVoucher = 'Sale Invoice (Cash Memo)';
  static const String purchaseVoucher = 'Purchase Invoice (Stock Inward)';
  static const String paymentInVoucher = 'Payment Received (Receipt)';
  static const String paymentOutVoucher = 'Payment Out (Distributor)';
  static const String filterAll = 'All Vouchers';

  // Bill Sharing & Printing
  static const String taxInvoice = 'RETAIL PHARMACY CASH MEMO / TAX INVOICE';
  static const String billDetails = 'Medicine Bill Details';
  static const String shareBillWhatsapp = 'Share Rx Bill on WhatsApp';
  static const String printBillThermal = 'Print Rx Thermal Bill (2/3 Inch)';
  static const String downloadPdf = 'Download PDF Invoice';
  static const String billSharedSuccess =
      'Prescription bill shared with patient on WhatsApp!';
  static const String billPrinting =
      'Connecting to Bluetooth/WiFi Thermal Printer...';
}
