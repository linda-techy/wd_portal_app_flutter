# Premium UI Implementation Guide

This guide provides instructions for applying the premium UI components across all screens in the application.

## ✅ Completed Components

All premium components have been created and are ready to use:

### Core Components
- ✅ `PremiumButton` (Primary, Secondary, Ghost, Danger, Icon)
- ✅ `PremiumTextInput`, `PremiumPasswordInput`, `PremiumSearchInput`, `PremiumTextArea`, `PremiumDropdownInput`
- ✅ `PremiumCard`, `ElevatedCard`, `Surface`
- ✅ `PremiumModal`, `PremiumBottomSheet`, `PremiumDrawer`
- ✅ `MotionToast` (enhanced with variants)
- ✅ `EmptyState`
- ✅ `ShimmerLoading`, `SkeletonLoader`, `PremiumSpinner`

### Animation Components
- ✅ `EntranceAnimation` (enhanced)
- ✅ `MotionButton` (enhanced)
- ✅ `PageTransition`
- ✅ `StaggeredList`, `StaggeredGrid`

### Accessibility
- ✅ `KeyboardNavigationWrapper`
- ✅ `SemanticButton`, `SemanticFormField`, `SemanticIconButton`
- ✅ `AccessibilityUtils`

## 📋 How to Apply Premium UI

### 1. Replace Buttons

**Before:**
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Submit'),
)
```

**After:**
```dart
PrimaryButton(
  label: 'Submit',
  onPressed: () {},
  icon: Icons.check,
)
```

### 2. Replace Input Fields

**Before:**
```dart
TextFormField(
  decoration: InputDecoration(labelText: 'Email'),
  controller: _emailController,
)
```

**After:**
```dart
PremiumTextInput(
  label: 'Email',
  controller: _emailController,
  prefixIcon: Icons.email_outlined,
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
)
```

### 3. Replace Cards

**Before:**
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Content'),
  ),
)
```

**After:**
```dart
PremiumCard(
  child: Text('Content'),
  onTap: () {}, // Optional
)
```

### 4. Replace Loading States

**Before:**
```dart
isLoading ? CircularProgressIndicator() : Content()
```

**After:**
```dart
isLoading 
  ? PremiumSpinner()
  : Content()

// Or for skeleton loading:
SkeletonLoader(type: SkeletonType.card)
```

### 5. Replace Toasts

**Before:**
```dart
MotionToast.show(context, message: 'Success', isError: false)
```

**After:**
```dart
MotionToast.showSuccess(context, message: 'Success')
// Or: MotionToast.showError(), showWarning(), showInfo()
```

### 6. Add Empty States

**Before:**
```dart
if (items.isEmpty) Text('No items')
```

**After:**
```dart
if (items.isEmpty)
  EmptyState(
    icon: Icons.inbox_outlined,
    title: 'No items found',
    message: 'Get started by adding your first item',
    actionLabel: 'Add Item',
    onAction: () {},
  )
```

### 7. Add Keyboard Navigation

Wrap forms and interactive sections:
```dart
KeyboardNavigationWrapper(
  child: Form(
    child: Column(
      children: [
        PremiumTextInput(...),
        PremiumPasswordInput(...),
        PrimaryButton(...),
      ],
    ),
  ),
)
```

### 8. Add Page Transitions

**Before:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => NextScreen()),
);
```

**After:**
```dart
Navigator.push(
  context,
  createPremiumPageRoute(page: NextScreen()),
);
```

## 🎨 Design Tokens Usage

Always use design tokens for spacing, typography, and colors:

```dart
// Spacing
padding: EdgeInsets.all(DesignTokens.spacingMD)
SizedBox(height: DesignTokens.spacingLG)

// Typography
TextStyle(fontSize: DesignTokens.fontSizeHeadlineMedium)

// Colors
color: DesignTokens.colorPrimary
backgroundColor: DesignTokens.colorSurface

// Border Radius
BorderRadius.circular(DesignTokens.radiusMD)

// Shadows
boxShadow: DesignTokens.getShadowForElevation(DesignTokens.elevation2)
```

## ♿ Accessibility Checklist

When applying premium UI, ensure:

- [ ] All buttons have semantic labels
- [ ] Form fields have proper labels and error announcements
- [ ] Interactive elements meet 44px minimum touch target
- [ ] Focus indicators are visible
- [ ] Keyboard navigation works (Tab, Enter, Esc)
- [ ] Screen reader announcements for errors/success

## 📱 Responsive Considerations

Use responsive utilities:

```dart
ResponsiveUtils.responsiveValue(
  context: context,
  mobile: 16.0,
  tablet: 24.0,
  desktop: 32.0,
)

ResponsiveLayout(
  mobile: MobileLayout(),
  desktop: DesktopLayout(),
)
```

## 🚀 Performance Tips

1. Use `const` constructors where possible
2. Wrap expensive widgets with `RepaintBoundary`
3. Use `AnimatedBuilder` for partial rebuilds
4. Lazy load lists with `ListView.builder`

## 📝 Screen-by-Screen Checklist

### Authentication Screens ✅
- [x] Login screen updated
- [ ] Registration screen (if exists)
- [ ] Password reset screen (if exists)

### Dashboard ✅
- [x] Main dashboard updated
- [ ] Loading states implemented
- [ ] Empty states added

### Forms
- [ ] Lead forms
- [ ] Customer forms
- [ ] Project forms
- [ ] All other form screens

### Data Tables
- [ ] Leads table
- [ ] Customers table
- [ ] Projects table
- [ ] All other tables

### Navigation
- [ ] Sidebar/Drawer
- [ ] Bottom navigation
- [ ] App bar

## 🎯 Priority Order

1. **High-traffic screens** (Dashboard, Login, Main forms)
2. **Data-heavy screens** (Tables, Lists)
3. **Form screens** (All input-heavy screens)
4. **Secondary screens** (Settings, Profile, etc.)

## 📚 Import Statements

Add these imports to screens using premium components:

```dart
import 'package:admin/widgets/components/premium_button.dart';
import 'package:admin/widgets/components/premium_input.dart';
import 'package:admin/widgets/components/premium_card.dart';
import 'package:admin/widgets/components/premium_modal.dart';
import 'package:admin/widgets/components/empty_state.dart';
import 'package:admin/widgets/animations/shimmer_loading.dart';
import 'package:admin/widgets/animations/page_transition.dart';
import 'package:admin/widgets/accessibility/keyboard_navigation.dart';
import 'package:admin/theme/design_tokens.dart';
import 'package:admin/utils/motion_toast.dart';
```

## ✨ Example: Complete Form Screen

```dart
class MyFormScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Form')),
      body: KeyboardNavigationWrapper(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(DesignTokens.spacingLG),
          child: Column(
            children: [
              PremiumTextInput(
                label: 'Name',
                prefixIcon: Icons.person,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: DesignTokens.spacingMD),
              PremiumPasswordInput(
                label: 'Password',
                validator: (v) => v?.length < 6 ? 'Too short' : null,
              ),
              SizedBox(height: DesignTokens.spacingLG),
              PrimaryButton(
                label: 'Submit',
                onPressed: () {
                  MotionToast.showSuccess(context, message: 'Saved!');
                },
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 🎉 Benefits

- **Consistent Design**: All screens use the same design system
- **Better UX**: Smooth animations and micro-interactions
- **Accessibility**: WCAG 2.2 AA compliant
- **Performance**: Optimized animations and rendering
- **Maintainability**: Centralized components and tokens
