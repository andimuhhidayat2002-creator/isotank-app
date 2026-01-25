# KAYAN LNG Brand Theme Implementation

## Overview
This document describes the implementation of KAYAN LNG brand identity across both web and Flutter applications.

## Brand Colors

### Primary Colors
- **Navy Blue**: `#2B4C7E` - Main brand color for headers, buttons, and primary elements
- **Navy Dark**: `#1E3A5F` - Darker variant for gradients and hover states
- **Navy Light**: `#3D5F8F` - Lighter variant for backgrounds and subtle elements

### Accent Colors
- **Orange**: `#FF6B35` - Primary accent for highlights, warnings, and CTAs
- **Orange Light**: `#FF8555` - Lighter variant for backgrounds
- **Orange Dark**: `#E55A2B` - Darker variant for hover states

### Supporting Colors
- **Sky Blue**: `#60A5FA` - Secondary accent from logo
- **White**: `#FFFFFF` - Primary background
- **Gray Scale**: `#F9FAFB` to `#111827` - Various gray shades for text and backgrounds

### Status Colors
- **Success**: `#10B981` (Green)
- **Warning**: `#FBBF24` (Yellow)
- **Error**: `#EF4444` (Red)
- **Info**: `#3B82F6` (Blue)

## Web Application (Laravel/Blade)

### Files Modified
1. **`api/resources/views/layouts/app.blade.php`**
   - Updated with KAYAN LNG theme
   - Added logo SVG in sidebar
   - Implemented CSS variables for colors
   - Enhanced sidebar navigation with icons
   - Improved user profile card styling

### Key Features
- **Sidebar**: Navy blue gradient background with KAYAN LNG logo
- **Navigation**: Icon-based menu items with orange accent for active states
- **Cards**: White background with subtle shadows and rounded corners
- **Buttons**: Gradient backgrounds with hover animations
- **Typography**: Inter font family with various weights

### CSS Variables
```css
:root {
    --kayan-navy: #2B4C7E;
    --kayan-navy-dark: #1E3A5F;
    --kayan-navy-light: #3D5F8F;
    --kayan-orange: #FF6B35;
    --kayan-orange-light: #FF8555;
    --kayan-orange-dark: #E55A2B;
    --kayan-blue: #60A5FA;
    --kayan-white: #FFFFFF;
    --kayan-gray-50: #F9FAFB;
    /* ... more colors */
}
```

## Flutter Application

### Files Created/Modified

#### 1. **`lib/ui/theme/kayan_theme.dart`**
Complete theme configuration including:
- `KayanColors` class with all brand colors
- `KayanTheme.lightTheme` with comprehensive Material 3 theming
- Custom styling for all Flutter widgets

#### 2. **`lib/ui/widgets/kayan_widgets.dart`**
Reusable widgets:
- `KayanStatusBadge` - Status indicators with brand colors
- `KayanSectionHeader` - Section headers with orange accent line
- `KayanInfoCard` - Information cards with gradient icons
- `KayanEmptyState` - Empty state placeholder
- `KayanLoadingIndicator` - Branded loading spinner
- `KayanActionButton` - Primary and secondary buttons

#### 3. **`lib/main.dart`**
- Updated to use `KayanTheme.lightTheme`
- Changed app title to "KAYAN LNG - Isotank Management"

### Usage Examples

#### Using Theme Colors
```dart
// In any widget
Container(
  color: KayanColors.navy,
  child: Text(
    'Hello',
    style: TextStyle(color: KayanColors.white),
  ),
)
```

#### Using Status Badge
```dart
KayanStatusBadge(
  label: 'ACTIVE',
  type: KayanStatusType.success,
)
```

#### Using Section Header
```dart
KayanSectionHeader(
  title: 'Inspection Details',
  subtitle: 'Review all inspection items',
  trailing: IconButton(
    icon: Icon(Icons.edit),
    onPressed: () {},
  ),
)
```

#### Using Info Card
```dart
KayanInfoCard(
  title: 'Total Isotanks',
  value: '120',
  icon: Icons.inventory,
  iconColor: KayanColors.navy,
  onTap: () {
    // Navigate to isotanks list
  },
)
```

## Logo Assets

### Web Application
- **Location**: `api/public/images/kayan_logo.png`
- **Usage**: Embedded as SVG in sidebar for crisp rendering

### Flutter Application
- **Location**: `assets/images/kayan_logo.png`
- **Usage**: Can be used with `Image.asset('assets/images/kayan_logo.png')`

## Typography

### Font Family
- **Primary**: Inter (Google Fonts)
- **Weights**: 300, 400, 500, 600, 700, 800

### Text Styles (Flutter)
- **Display Large**: 32px, Weight 800, Navy
- **Headline Large**: 22px, Weight 700, Navy
- **Title Large**: 18px, Weight 600, Gray 900
- **Body Large**: 16px, Weight 400, Gray 900
- **Label Large**: 15px, Weight 600, Gray 900

## Design Principles

### 1. **Professional & Industrial**
- Clean, modern design suitable for industrial LNG operations
- Professional color palette with navy blue as primary
- Clear hierarchy and readable typography

### 2. **Consistent Branding**
- KAYAN LNG logo prominently displayed
- Consistent use of brand colors across all interfaces
- Orange accent used sparingly for emphasis

### 3. **User-Friendly**
- High contrast for readability
- Clear visual feedback for interactions
- Intuitive navigation with icons

### 4. **Modern & Premium**
- Gradient backgrounds for depth
- Smooth animations and transitions
- Card-based layouts with subtle shadows

## Component Styling Guidelines

### Buttons
- **Primary**: Navy blue background, white text
- **Secondary**: White background, navy border
- **Warning/Accent**: Orange background, white text
- **Padding**: 10-14px vertical, 20-24px horizontal
- **Border Radius**: 8-10px

### Cards
- **Background**: White
- **Border Radius**: 12px
- **Shadow**: Subtle (0 1px 3px rgba(0,0,0,0.08))
- **Hover**: Elevated shadow (0 4px 12px rgba(0,0,0,0.12))

### Status Indicators
- **Success**: Green background (#D1FAE5), dark green text
- **Warning**: Light orange background, dark orange text
- **Error**: Light red background, dark red text
- **Info**: Light blue background, dark blue text

### Navigation
- **Active State**: Orange gradient background
- **Hover State**: White overlay (15% opacity)
- **Icons**: 20px size, consistent spacing

## Deployment Notes

### Web Application
1. Logo is embedded as inline SVG (no external file needed for sidebar)
2. All styles are in `app.blade.php` (no separate CSS file required)
3. Uses Bootstrap 5 and Bootstrap Icons
4. Compatible with existing DataTables styling

### Flutter Application
1. Ensure `google_fonts` package is in `pubspec.yaml`
2. Logo asset must be declared in `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/images/kayan_logo.png
   ```
3. Theme is automatically applied via `MaterialApp`
4. Widgets are available for import from `ui/widgets/kayan_widgets.dart`

## Future Enhancements

### Potential Additions
1. **Dark Mode**: Create dark theme variant
2. **Animations**: Add micro-interactions for better UX
3. **Responsive**: Optimize for different screen sizes
4. **Accessibility**: Ensure WCAG compliance
5. **Custom Icons**: Create KAYAN LNG specific icon set

## References

### Design Inspiration
- Modern industrial design
- Professional SaaS applications
- Material Design 3 guidelines

### Color Psychology
- **Navy Blue**: Trust, professionalism, stability
- **Orange**: Energy, innovation, action
- **White**: Cleanliness, clarity, simplicity

---

**Last Updated**: 2026-01-18
**Version**: 1.0.0
**Maintained By**: Development Team
