# Design System Documentation

**Date**: 2026-06-25

---

## Overview

The Apex Design System is a comprehensive set of design tokens and reusable components that ensure consistency across the entire application.

---

## Design Tokens

### Colors (`design_system/colors.dart`)

**Primary (Deep Navy)**
- primary: #1E3A8A
- primary50-900: Light to dark variants

**Secondary (Teal)**
- secondary: #0D9488
- secondary50-700: Light to dark variants

**Accent (Amber)**
- accent: #F59E0B
- accent50-600: Light to dark variants

**Neutral**
- neutral0-900: White to near-black

**Status**
- success: #22C55E
- warning: #F59E0B
- error: #EF4444
- info: #3B82F6

**Dark Mode**
- darkBackground: #0F172A
- darkSurface: #1E293B
- darkSurfaceVariant: #334155

---

### Typography (`design_system/typography.dart`)

**Font Family**: Inter (Google Fonts)

| Style | Size | Weight | Height | Usage |
|-------|------|--------|--------|-------|
| displayLarge | 48 | 700 | 1.1 | Hero sections |
| displayMedium | 36 | 700 | 1.15 | Large headings |
| displaySmall | 30 | 600 | 1.2 | Section headings |
| headingLarge | 24 | 700 | 1.3 | Page titles |
| headingMedium | 20 | 600 | 1.35 | Card titles |
| headingSmall | 18 | 600 | 1.4 | Section titles |
| titleLarge | 16 | 600 | 1.4 | List titles |
| titleMedium | 14 | 600 | 1.45 | Card subtitles |
| titleSmall | 12 | 600 | 1.5 | Labels |
| bodyLarge | 16 | 400 | 1.5 | Body text |
| bodyMedium | 14 | 400 | 1.5 | Default text |
| bodySmall | 12 | 400 | 1.5 | Captions |
| captionLarge | 12 | 500 | 1.5 | Badges |
| captionMedium | 11 | 500 | 1.5 | Small labels |
| captionSmall | 10 | 500 | 1.5 | Tiny labels |

---

### Spacing (`design_system/spacing.dart`)

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4 | Tight spacing |
| sm | 8 | Small gaps |
| md | 12 | Medium gaps |
| base | 16 | Default padding |
| lg | 24 | Section spacing |
| xl | 32 | Large spacing |
| xxl | 48 | Page margins |
| xxxl | 64 | Hero spacing |

---

### Border Radius (`design_system/border_radius.dart`)

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4 | Subtle rounding |
| sm | 6 | Small elements |
| md | 8 | Cards, inputs |
| lg | 12 | Cards, dialogs |
| xl | 16 | Large cards |
| xxl | 24 | Pills |
| full | 999 | Circles |

---

### Elevation (`design_system/elevation.dart`)

| Token | Blur | Offset | Usage |
|-------|------|--------|-------|
| none | 0 | 0 | Flat |
| xs | 2 | 1 | Subtle |
| sm | 4 | 1 | Cards |
| md | 8 | 2 | Hover |
| lg | 16 | 4 | Modals |
| xl | 24 | 8 | Popovers |

---

## Components

### ApexCard
Consistent card with hover states, padding, and optional header/footer.

### ApexButton
Primary, secondary, ghost, danger, success variants in sm/md/lg sizes.

### ApexBadge
Status badges with color-coded backgrounds.

### ApexTable
Sortable, filterable data table with sticky headers.

### ApexEmptyState
Illustrated empty states with optional action button.

### ApexLoadingSkeleton
Shimmer loading skeletons for list, card, table, stat.

### ApexStatCard
Enhanced stat card with trend indicator.

### ApexSearchBar
Search input with keyboard shortcut hint.

### ApexFilterBar
Horizontal scrollable filter chips.

### ApexBreadcrumb
Navigation breadcrumb trail.

---

## Usage Guidelines

1. **Always use design tokens** instead of hardcoded values
2. **Use components** instead of building custom UI
3. **Follow spacing scale** for consistent layout
4. **Use status colors** for state indicators
5. **Maintain hierarchy** with typography scale
