# Digital Signature System Implementation Plan

## Overview
Implement a comprehensive digital signature system for Inspectors (profile-based, reusable) and Receivers (event-based, non-reusable) to ensure authenticity and traceability of inspection reports.

## 1. Database Migrations

### A. Users Table (Inspector Signature)
Modifications to `users` table:
- `signature_path` (string, nullable): Path to the inspector's stored PNG signature.
- `signature_updated_at` (timestamp, nullable): Audit trail for when the signature was last updated.

### B. Inspection Logs Table (Receiver Signature)
Modifications to `inspection_logs` table:
- `receiver_signature_path` (string, nullable): Path to the receiver's one-time signature for outgoing inspections.
- `receiver_signed_at` (timestamp, nullable): Exact time of signing (distinct from `receiver_confirmed_at` if needed, though likely same).

## 2. Backend Implementation (Laravel)

### A. Inspector Signature (Profile)
- **Controller**: `ProfileController` (or `UserController`)
- **Endpoint**: `POST /api/profile/signature`
- **Logic**:
  - Accept `image` file.
  - Store in `public/signatures/inspectors/{user_id}.png`.
  - Update `users` table.
  - Prevent deletion of old files (rename instead of overwrite if strict audit needed, currently user said "old files MUST NOT be deleted").
    - *Strategy*: Store new file with timestamp `signatures/inspectors/{user_id}_{timestamp}.png`.

### B. Receiver Signature (Transaction)
- **Controller**: `ReceiverConfirmationController`
- **Method**: `submit`
- **Logic**:
  - Accept `signature_image` in the confirmation payload.
  - Store in `public/signatures/receivers/{inspection_id}_{timestamp}.png`.
  - Update `inspection_logs` with path.
  - Ensure this is done atomically with item confirmations.

### C. PDF Generation
- **Service**: `PdfService`
- **Logic**:
  - **Inspector**: Fetch `inspector->signature_path`. Embed in PDF footer/header.
  - **Receiver**: Fetch `inspection_log->receiver_signature_path`. Embed in "Receiver Acceptance" section.
  - **Layout**: Ensure both signatures appear on the final report.

## 3. Frontend Implementation (Flutter)

### A. Inspector Profile
- **UI**: Add "Digital Signature" tile in `ProfileScreen` / `SettingsScreen`.
- **Feature**:
  - View current signature.
  - "Update Signature" button -> Opens Signature Pad (Draw) or Gallery (Upload).
  - Save -> Uploads to API.

### B. Receiver Confirmation Screen
- **UI**: Add "Receiver Signature" step after item checklist.
- **Feature**:
  - Mandatory Signature Pad.
  - "Clear" and "Save" buttons.
  - On "Submit Confirmation": Include signature image file in Multipart request.

## 4. Security & Rules
- **Inspector**: Signature is locked to account. Auto-applies to new PDFs.
- **Receiver**: Signature is locked to Inspection ID. Cannot be reused.
- **Validation**:
  - Receiver cannot submit outgoing inspection without signature.
  - Inspector is prompted to set up signature if missing (optional enhancement).

## 5. Workflow
1. **Inspector Setup**: Go to Profile -> Draw Signature -> Save.
2. **Inspection**: Perform inspection -> Submit.
3. **PDF**: PDF now shows Inspector Signature automatically.
4. **Outgoing**:
   - Receiver checks items.
   - Receiver signs on device.
   - Submit.
5. **Final PDF**: Shows Inspector + Receiver Signatures.
