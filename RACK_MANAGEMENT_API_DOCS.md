# Pharmacy Rack & Physical Storage Management API Documentation
**Target Audience:** Frontend Web Developers & Mobile App Developers  
**Base URL:** `http://134.195.138.153:5095/api/v1` (or your local `http://localhost:5095/api/v1`)  
**Prefix:** `/inventory/racks`

---

## 1. Authentication & Common Headers

Every request requires a valid JWT token issued by Keycloak and tenant shop context.

```http
Authorization: Bearer <jwt_token>
x-shop-id: <shop_uuid>
Content-Type: application/json
```

### Standard Response Envelope
All API responses follow a uniform JSON structure:

```json
// Successful Response
{
  "success": true,
  "message": "Resource retrieved successfully",
  "data": { ... },
  "meta": { "timestamp": "2026-09-15T11:00:00.000Z" }
}

// Error Response
{
  "success": false,
  "code": "BAD_REQUEST",
  "message": "Validation failed: code is required",
  "details": [ ... ]
}
```

---

## 2. Enums & Reference Constants

### Zones (`zone`)
| Value | Description | Use Case |
|---|---|---|
| `MAIN_COUNTER` | Immediately behind the billing desk | Fast-moving OTC, seasonal fever/cold |
| `BACK_STORAGE` | Main rear storage aisles | Bulk cartons, secondary stock |
| `COLD_STORAGE` | Refrigerator (2°C – 8°C) | Insulin, vaccines, eye drops |
| `NARCOTICS_LOCKER` | Double-locked Schedule H1/X safe | Habit-forming, sedative formulations |
| `OTC_FLOOR` | Customer self-service shelves | Energy drinks, balms, health foods |
| `GENERAL` | General shelving | Uncategorized items |

### Storage Types (`storageType`)
- `STANDARD`
- `REFRIGERATED`
- `NARCOTICS_SAFE`
- `HAZARDOUS`

### Rack Status (`status`)
- `ACTIVE`
- `MAINTENANCE`
- `INACTIVE`

---

## 3. Endpoints Reference

### 3.1. List Racks (with Occupancy & Counts)
Retrieves all racks configured for the active shop, including total shelves, active medicine counts, and calculated occupancy percentages.

- **Method:** `GET`
- **Path:** `/inventory/racks`
- **Roles:** `Admin`, `Pharmacist`, `Cashier`, `Staff`

#### Query Parameters:
| Parameter | Type | Required | Description |
|---|---|---|---|
| `zone` | `string` | No | Filter by zone (e.g. `MAIN_COUNTER`, `COLD_STORAGE`) |
| `storageType` | `string` | No | Filter by storage type (`STANDARD`, `REFRIGERATED`, etc.) |
| `status` | `string` | No | `ACTIVE`, `MAINTENANCE`, `INACTIVE` |
| `search` | `string` | No | Matches rack code, name, or description |

#### Response Example:
```json
{
  "success": true,
  "message": "Racks retrieved successfully",
  "data": [
    {
      "id": "e7b0a701-a1b2-4c3d-8e4f-123456789abc",
      "code": "A",
      "name": "Antibiotics Front Counter",
      "zone": "MAIN_COUNTER",
      "storageType": "STANDARD",
      "description": "Oral cephalosporins and fluoroquinolones",
      "totalShelves": 4,
      "qrCode": "RACK:A:12345678",
      "status": "ACTIVE",
      "activeMedicinesCount": 42,
      "totalCapacity": 400,
      "occupancyPercentage": 11,
      "shelves": [
        { "id": "s-1", "shelfNumber": 1, "shelfLabel": "Shelf 1", "maxCapacity": 100, "barcode": "A-S1" },
        { "id": "s-2", "shelfNumber": 2, "shelfLabel": "Shelf 2", "maxCapacity": 100, "barcode": "A-S2" },
        { "id": "s-3", "shelfNumber": 3, "shelfLabel": "Shelf 3", "maxCapacity": 100, "barcode": "A-S3" },
        { "id": "s-4", "shelfNumber": 4, "shelfLabel": "Shelf 4", "maxCapacity": 100, "barcode": "A-S4" }
      ]
    }
  ]
}
```

---

### 3.2. Get Rack Details (with Visual Shelf-by-Shelf Layout)
Returns complete information for an individual rack, including its shelves and all active medicines grouped by shelf number.

- **Method:** `GET`
- **Path:** `/inventory/racks/:id`
- **Roles:** All authenticated roles

#### Response Example:
```json
{
  "success": true,
  "message": "Rack details retrieved successfully",
  "data": {
    "id": "e7b0a701-a1b2-4c3d-8e4f-123456789abc",
    "code": "A",
    "name": "Antibiotics Front Counter",
    "zone": "MAIN_COUNTER",
    "totalShelves": 4,
    "totalMedicines": 2,
    "shelves": [
      { "id": "s-1", "shelfNumber": 1, "shelfLabel": "Shelf 1", "bins": [] }
    ],
    "medicinesByShelf": {
      "1": [
        {
          "id": "med-1",
          "name": "Augmentin 625 Duo Tablet",
          "genericName": "Amoxicillin and Potassium Clavulanate",
          "dosageForm": "Tablet",
          "strength": "625mg",
          "rack": "A",
          "shelf": "1",
          "box": "02",
          "batches": [
            {
              "id": "b-1",
              "batchNumber": "AUG2024-01",
              "expiryDate": "2027-04-30T00:00:00.000Z",
              "currentQuantity": 60,
              "status": "ACTIVE"
            }
          ]
        }
      ]
    }
  }
}
```

---

### 3.3. Create New Rack
Creates a rack and automatically provisions shelves from `Shelf 1` to `Shelf N`.

- **Method:** `POST`
- **Path:** `/inventory/racks`
- **Roles:** `Admin`, `Pharmacist`

#### Request Body:
```json
{
  "code": "C",
  "name": "Cough & Cold Syrups",
  "zone": "MAIN_COUNTER",
  "storageType": "STANDARD",
  "description": "Near dispensing area",
  "totalShelves": 5,
  "rowNumber": 1,
  "columnNumber": 3
}
```

#### Response `201 Created`:
```json
{
  "success": true,
  "message": "Rack created successfully with initial shelves",
  "data": {
    "id": "uuid",
    "code": "C",
    "name": "Cough & Cold Syrups",
    "totalShelves": 5,
    "qrCode": "RACK:C:12345678",
    "shelves": [ ...5 shelves created... ]
  }
}
```

---

### 3.4. Update Rack
- **Method:** `PATCH`
- **Path:** `/inventory/racks/:id`
- **Roles:** `Admin`, `Pharmacist`

#### Request Body:
```json
{
  "name": "Renamed Rack",
  "totalShelves": 6,
  "zone": "BACK_STORAGE",
  "status": "ACTIVE"
}
```
*(If `totalShelves` is increased, the API automatically provisions the extra shelves)*

---

### 3.5. Delete Rack
- **Method:** `DELETE`
- **Path:** `/inventory/racks/:id`
- **Roles:** `Admin`

> **Note:** Will return `400 BAD_REQUEST` if medicines are still assigned to this rack. Reassign medicines before deleting.

---

### 3.6. Assign Medicine to Rack / Shelf / Box
Directly assigns a single medicine to a physical rack slot. Updates denormalized location fields for fast search.

- **Method:** `POST`
- **Path:** `/inventory/racks/assign`
- **Roles:** `Admin`, `Pharmacist`

#### Request Body:
```json
{
  "medicineId": "34988718-498c-450f-90e8-fa327a3c3187",
  "rackCode": "A",
  "shelfNumber": "2",
  "boxCode": "05"
}
```

#### Response Example:
```json
{
  "success": true,
  "message": "Medicine assigned to rack location successfully",
  "data": {
    "id": "34988718-498c-450f-90e8-fa327a3c3187",
    "name": "Cheston Cold Total Tablet",
    "rack": "A",
    "shelf": "2",
    "box": "05",
    "locationFormatted": "Rack A • Shelf 2 • Box 05"
  }
}
```

---

### 3.7. Bulk Assign Medicines
Used for initial store setup, CSV import, or bulk shelf reorganization.

- **Method:** `POST`
- **Path:** `/inventory/racks/bulk-assign`
- **Roles:** `Admin`, `Pharmacist`

#### Request Body:
```json
{
  "assignments": [
    { "medicineId": "uuid-1", "rackCode": "A", "shelfNumber": "1", "boxCode": "01" },
    { "medicineId": "uuid-2", "rackCode": "A", "shelfNumber": "1", "boxCode": "02" },
    { "medicineId": "uuid-3", "rackCode": "B", "shelfNumber": "3", "boxCode": "10" }
  ]
}
```

#### Response Example:
```json
{
  "success": true,
  "message": "Bulk assigned 3 medicines successfully",
  "data": {
    "assignedCount": 3,
    "failedCount": 0,
    "errors": []
  }
}
```

---

### 3.8. Transfer / Reorganize Medicines
Moves multiple medicines from their current locations to a new target rack and shelf in one call.

- **Method:** `POST`
- **Path:** `/inventory/racks/transfer`
- **Roles:** `Admin`, `Pharmacist`

#### Request Body:
```json
{
  "medicineIds": ["med-id-1", "med-id-2"],
  "targetRackCode": "C",
  "targetShelfNumber": "1",
  "targetBoxCode": "08",
  "reason": "Moved seasonal winter medicines to front desk"
}
```

#### Response Example:
```json
{
  "success": true,
  "message": "Medicines transferred to target rack successfully",
  "data": {
    "transferredCount": 2,
    "targetRackCode": "C",
    "targetShelf": "1",
    "targetBox": "08",
    "reason": "Moved seasonal winter medicines to front desk"
  }
}
```

---

### 3.9. Get Unassigned Medicines
Finds all active medicines in the store that do not currently have a rack or shelf assigned.

- **Method:** `GET`
- **Path:** `/inventory/racks/unassigned`
- **Roles:** `Admin`, `Pharmacist`, `Staff`

#### Query Parameters:
| Parameter | Type | Default | Description |
|---|---|---|---|
| `page` | `number` | `1` | Page number |
| `limit` | `number` | `20` | Items per page (max 100) |
| `search` | `string` | - | Search by medicine name or generic |

---

### 3.10. Fast Counter Locator (for POS Billing Screens)
Sub-millisecond lookup returning exact rack coordinates and live batch stock for instant counter picking.

- **Method:** `GET`
- **Path:** `/inventory/racks/locate/:medicineId`
- **Roles:** All authenticated roles

#### Response Example:
```json
{
  "success": true,
  "message": "Medicine coordinates located successfully",
  "data": {
    "medicineId": "med-uuid",
    "name": "Cheston Cold Total Tablet",
    "genericName": "Cetirizine + Paracetamol + Phenylephrine",
    "coordinates": {
      "rackId": "rack-uuid",
      "rackCode": "C",
      "rackName": "Front Cold Section",
      "zone": "MAIN_COUNTER",
      "storageType": "STANDARD",
      "shelf": "1",
      "box": "05",
      "formatted": "Rack C • Shelf 1 • Box 05"
    },
    "stock": {
      "totalStock": 48,
      "batchesCount": 2,
      "batches": [
        {
          "id": "b-1",
          "batchNumber": "CC2401",
          "expiryDate": "2027-02-28T00:00:00.000Z",
          "currentQuantity": 48,
          "status": "ACTIVE"
        }
      ]
    }
  }
}
```

---

### 3.11. Physical Stocktake Audit Sheet
Generates a shelf-by-shelf audit sheet with all batches expected to be physically located on that rack.

- **Method:** `GET`
- **Path:** `/inventory/racks/:id/audit-sheet`
- **Roles:** `Admin`, `Pharmacist`

#### Response Example:
```json
{
  "success": true,
  "message": "Rack audit sheet generated successfully",
  "data": {
    "rackId": "rack-uuid",
    "rackCode": "A",
    "rackName": "Antibiotics Front Counter",
    "zone": "MAIN_COUNTER",
    "generatedAt": "2026-09-15T11:18:53.085Z",
    "totalBatchesToCheck": 14,
    "items": [
      {
        "medicineId": "med-1",
        "medicineName": "Augmentin 625 Duo",
        "shelf": "1",
        "box": "02",
        "batchId": "batch-1",
        "batchNumber": "AUG2024-01",
        "expiryDate": "2027-04-30T00:00:00.000Z",
        "mrp": "223.50",
        "systemStock": 60
      }
    ]
  }
}
```

---

### 3.12. Submit Physical Stock Verification
Submits physical stock counts from a barcode scan / clipboard audit. If physical counts differ from system stock, it automatically logs stock adjustment transactions (`ADJUSTMENT_ADD` or `ADJUSTMENT_SUB`) and reconciles the batch quantity.

- **Method:** `POST`
- **Path:** `/inventory/racks/:id/audit-verify`
- **Roles:** `Admin`, `Pharmacist`

#### Request Body:
```json
{
  "auditItems": [
    {
      "batchId": "batch-1",
      "physicalCount": 58,
      "systemCount": 60,
      "notes": "2 damaged strips removed during shelf check"
    }
  ]
}
```

#### Response Example:
```json
{
  "success": true,
  "message": "Physical stock verification submitted and reconciled",
  "data": {
    "rackCode": "A",
    "totalItemsAudited": 1,
    "adjustmentsRecorded": 1,
    "status": "COMPLETED"
  }
}
```

---

## 4. TypeScript Interfaces (Copy-Paste Ready for App Dev)

```typescript
export interface RackItem {
  id: string;
  code: string;
  name: string;
  zone: "MAIN_COUNTER" | "BACK_STORAGE" | "COLD_STORAGE" | "NARCOTICS_LOCKER" | "OTC_FLOOR" | "GENERAL";
  storageType: "STANDARD" | "REFRIGERATED" | "NARCOTICS_SAFE" | "HAZARDOUS";
  description?: string | null;
  totalShelves: number;
  qrCode?: string | null;
  status: "ACTIVE" | "MAINTENANCE" | "INACTIVE";
  activeMedicinesCount: number;
  totalCapacity: number;
  occupancyPercentage: number;
  shelves: RackShelfItem[];
}

export interface RackShelfItem {
  id: string;
  shelfNumber: number;
  shelfLabel?: string | null;
  barcode?: string | null;
  maxCapacity?: number | null;
  temperature?: number | null;
}

export interface MedicineLocationCoordinates {
  rackId?: string | null;
  rackCode: string;
  rackName?: string | null;
  zone: string;
  storageType: string;
  shelf: string;
  box?: string | null;
  formatted: string;
}

export interface LocateMedicineResult {
  medicineId: string;
  name: string;
  genericName: string;
  coordinates: MedicineLocationCoordinates;
  stock: {
    totalStock: number;
    batchesCount: number;
    batches: Array<{
      id: string;
      batchNumber: string;
      expiryDate: string;
      currentQuantity: number;
      status: string;
    }>;
  };
}
```

---

## 5. UI Integration Recommendations

1. **POS Quick Pick Badge:**  
   In the POS medicine search dropdown, render `item.locationFormatted` as a clickable chip (e.g. `📍 Rack A • Shelf 2 • Box 05`). Clicking it can trigger a visual mini-map of Rack A showing Shelf 2 highlighted.
2. **Cold Chain Badge:**  
   If `coordinates.storageType === "REFRIGERATED"`, display a `❄️ Cold Storage (2°C-8°C)` blue badge to remind the shop-boy to pick it from the refrigerator.
3. **Narcotics Alert:**  
   If `coordinates.storageType === "NARCOTICS_SAFE"`, display a `🔒 Schedule H1 Locker` icon and prompt for key holder confirmation.
4. **Mobile Barcode Audit:**  
   In the mobile app, store staff can scan the shelf barcode (e.g., `A-S1`), which loads the audit sheet directly for that shelf.
