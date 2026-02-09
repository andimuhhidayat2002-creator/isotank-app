# Flutter UI/UX Fixes - Implementation Plan

## Issues to Fix

### 1. Isotank Lookup Navigation (CRITICAL)
**Problem:** "Isotank Lookup" button navigates to Yard Positioning instead of Isotank Detail Search
**Solution:**
- Create new `IsotankLookupScreen` with search functionality
- Shows isotank details from web (master data)
- Update `inspector_dashboard.dart` line 164 to navigate to new screen

### 2. Inspection Header Text Color (HIGH)
**Problem:** Header items in inspection are white on white background (unreadable)
**Files to check:**
- `lib/ui/screens/inspector/inspector_jobs_screen.dart`
- Any inspection detail screens
**Solution:** Change text color to dark or use theme colors properly

### 3. Maintenance Status Text Color (HIGH)
**Problem:** Status text in maintenance is hard to read
**Files to check:**
- `lib/ui/screens/maintenance/maintenance_dashboard.dart`
- Maintenance job list/detail screens
**Solution:** Fix text contrast for status badges

### 4. Missing Inspection Items (CRITICAL)
**Problem:** Missing multi-stage readings:
- Pressure 1 & 2 (for Pressure Gauge)
- Level 1 & 2 (for Level Gauge)  
- Temperature 1 & 2 (for IBOX)

**Current State:** Need to check what inspection items are being fetched
**Solution:** Ensure API returns all items and UI displays them correctly

### 5. Incoming/Outgoing Separation (HIGH)
**Problem:** Outgoing inspections still show Incoming inside
**Files to check:**
- `lib/ui/screens/inspector/inspector_jobs_screen.dart`
**Solution:** Properly filter by inspection_type (incoming vs outgoing)

## Implementation Order

1. Fix Isotank Lookup navigation (create new screen)
2. Fix text colors (inspection headers + maintenance status)
3. Verify inspection items completeness
4. Fix Incoming/Outgoing filtering

## Files to Modify

1. `lib/ui/screens/inspector/inspector_dashboard.dart` - Fix navigation
2. `lib/ui/screens/inspector/isotank_lookup_screen.dart` - NEW FILE
3. `lib/ui/screens/inspector/inspector_jobs_screen.dart` - Fix colors & filtering
4. `lib/ui/screens/maintenance/*` - Fix status colors
5. Inspection detail screens - Verify all items display

## Testing Checklist

- [ ] Isotank Lookup opens correct screen
- [ ] Can search and view isotank details
- [ ] Inspection headers are readable
- [ ] Maintenance status is readable
- [ ] All pressure/level/temp readings show
- [ ] Incoming only shows incoming jobs
- [ ] Outgoing only shows outgoing jobs
