# Component Library

**Date**: 2026-06-25

---

## Components

### ApexCard
**File**: `design_system/components/apex_card.dart`

Consistent card with hover states, padding, and optional header/footer.

**Properties**:
- `child`: Widget content
- `padding`: Content padding
- `margin`: Outer margin
- `onTap`: Tap handler
- `selected`: Selected state
- `elevated`: Force elevation
- `header`: Header widget
- `footer`: Footer widget
- `backgroundColor`: Custom background

**Usage**:
```dart
ApexCard(
  header: Text('Title'),
  child: Text('Content'),
  onTap: () => {},
)
```

---

### ApexButton
**File**: `design_system/components/apex_button.dart`

Button with variants: primary, secondary, ghost, danger, success.

**Variants**:
- `ApexButton.primary()`
- `ApexButton.secondary()`
- `ApexButton.ghost()`
- `ApexButton.danger()`

**Sizes**: sm, md, lg

**Properties**:
- `label`: Button text
- `icon`: Leading icon
- `onPressed`: Tap handler
- `loading`: Loading state
- `fullWidth`: Full width

---

### ApexBadge
**File**: `design_system/components/apex_badge.dart`

Status badge with color-coded background.

**Categories**:
- `attendance`: present, late, absent, half_day, on_leave
- `device`: online, offline, error, testing
- `leave`: pending, approved, rejected
- `employee`: active, inactive

**Properties**:
- `status`: Status string
- `category`: Category string
- `dot`: Show as dot indicator
- `outlined`: Outlined style

---

### ApexTable
**File**: `design_system/components/apex_table.dart`

Sortable data table with sticky headers.

**Properties**:
- `columns`: List of ApexTableColumn
- `data`: List of data items
- `rowBuilder`: Row builder function
- `showCheckbox`: Show selection checkbox
- `selectedItems`: Selected items set
- `sortColumnIndex`: Current sort column
- `sortAscending`: Sort direction
- `onSort`: Sort callback

---

### ApexEmptyState
**File**: `design_system/components/apex_empty_state.dart`

Illustrated empty state with action.

**Properties**:
- `icon`: Icon to display
- `title`: Title text
- `description`: Description text
- `actionLabel`: Action button label
- `onAction`: Action callback

---

### ApexLoadingSkeleton
**File**: `design_system/components/apex_loading_skeleton.dart`

Shimmer loading skeleton.

**Types**:
- `ApexSkeletonType.list`: List item skeleton
- `ApexSkeletonType.card`: Card skeleton
- `ApexSkeletonType.table`: Table row skeleton
- `ApexSkeletonType.stat`: Stat card skeleton

---

### ApexStatCard
**File**: `design_system/components/apex_stat_card.dart`

Enhanced stat card with trend.

**Properties**:
- `title`: Stat title
- `value`: Stat value
- `icon`: Leading icon
- `color`: Accent color
- `trend`: Trend text
- `isTrendPositive`: Trend direction
- `onTap`: Tap handler

---

### ApexSearchBar
**File**: `design_system/components/apex_search_bar.dart`

Search input with keyboard shortcut hint.

**Properties**:
- `hintText`: Placeholder text
- `onSearch`: Submit callback
- `onChanged`: Change callback
- `showShortcut`: Show ⌘K hint

---

### ApexFilterBar
**File**: `design_system/components/apex_filter_bar.dart`

Horizontal scrollable filter chips.

**Properties**:
- `filters`: List of ApexFilter
- `onClearAll`: Clear all callback

---

### ApexBreadcrumb
**File**: `design_system/components/apex_breadcrumb.dart`

Navigation breadcrumb trail.

**Properties**:
- `items`: List of ApexBreadcrumbItem

---

## Patterns

### Loading State
```dart
state.when(
  loading: () => const ApexLoadingSkeleton(count: 5, type: ApexSkeletonType.list),
  data: (data) => _buildContent(data),
  error: (err, stack) => _buildError(err),
)
```

### Empty State
```dart
if (items.isEmpty)
  return const ApexEmptyState(
    icon: Icons.inbox,
    title: 'No Items',
    description: 'Items will appear here.',
    actionLabel: 'Add Item',
  )
```

### Status Badge
```dart
ApexBadge(status: 'present', category: 'attendance')
ApexBadge(status: 'online', category: 'device', dot: true)
```
