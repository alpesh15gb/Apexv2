# Design System V2: Apex HRMS

**Date**: 2026-06-26

---

## Typography

### Font Family
- **Primary**: Inter (Google Fonts)
- **Monospace**: JetBrains Mono (for codes)

### Type Scale

| Style | Size | Weight | Height | Usage |
|-------|------|--------|--------|-------|
| Display Large | 48px | 700 | 1.1 | Hero sections |
| Display Medium | 36px | 700 | 1.15 | Splash screens |
| Page Title | 24px | 700 | 1.3 | Page headings |
| Section Header | 11px | 600 | 1.4 | Section labels |
| KPI Value | 28px | 700 | 1.2 | Dashboard metrics |
| KPI Label | 11px | 500 | 1.4 | Metric labels |
| Heading Large | 20px | 700 | 1.3 | Card titles |
| Heading Medium | 16px | 600 | 1.35 | Section titles |
| Heading Small | 14px | 600 | 1.4 | Subsection titles |
| Title Large | 15px | 600 | 1.4 | List titles |
| Title Medium | 13px | 600 | 1.45 | Card subtitles |
| Title Small | 12px | 600 | 1.5 | Labels |
| Body Large | 15px | 400 | 1.5 | Long text |
| Body Medium | 13px | 400 | 1.5 | Default text |
| Body Small | 12px | 400 | 1.5 | Captions |
| Table Header | 11px | 600 | 1.4 | Table headers |
| Table Cell | 13px | 400 | 1.4 | Table cells |
| Caption Large | 12px | 500 | 1.5 | Badges |
| Caption Medium | 11px | 500 | 1.5 | Small labels |
| Caption Small | 10px | 500 | 1.5 | Tiny labels |
| Button Large | 14px | 600 | 1.3 | Large buttons |
| Button Medium | 13px | 600 | 1.3 | Default buttons |
| Button Small | 12px | 600 | 1.3 | Small buttons |

---

## Spacing

### Scale
- **xs**: 4px
- **sm**: 8px
- **md**: 12px
- **base**: 16px
- **lg**: 24px
- **xl**: 32px
- **xxl**: 48px

### Usage
- **Page padding**: 24px desktop, 16px mobile
- **Card padding**: 12-14px
- **Section gap**: 16px between sections
- **Related gap**: 8px between related elements
- **Table row padding**: 8px vertical

---

## Colors

### Primary
- **Primary**: #1E3A8A (Deep Navy)
- **Primary 50**: #EFF6FF
- **Primary 100**: #DBEAFE
- **Primary 200**: #BFDBFE
- **Primary 300**: #93C5FD
- **Primary 400**: #60A5FA
- **Primary 500**: #3B82F6

### Status
- **Success**: #22C55E
- **Warning**: #F59E0B
- **Error**: #EF4444
- **Info**: #3B82F6

### Neutral
- **0**: #FFFFFF
- **50**: #F8FAFC
- **100**: #F1F5F9
- **200**: #E2E8F0
- **300**: #CBD5E1
- **400**: #94A3B8
- **500**: #64748B
- **600**: #475569
- **700**: #334155
- **800**: #1E293B
- **900**: #0F172A

---

## Elevation

| Level | Shadow | Usage |
|-------|--------|-------|
| None | none | Flat elements |
| XS | 0 1px 2px rgba(0,0,0,0.05) | Subtle elevation |
| SM | 0 1px 3px rgba(0,0,0,0.1) | Cards |
| MD | 0 4px 6px rgba(0,0,0,0.1) | Dropdowns |
| LG | 0 10px 15px rgba(0,0,0,0.1) | Modals |
| XL | 0 20px 25px rgba(0,0,0,0.15) | Popovers |

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Small elements |
| sm | 6px | Buttons, inputs |
| md | 8px | Cards |
| lg | 12px | Large cards |
| xl | 16px | Modals |
| full | 999px | Pills, circles |

---

## Components

### Buttons
- **Primary**: Filled, blue
- **Secondary**: Outlined
- **Ghost**: No border, text only
- **Danger**: Red

### Cards
- **Default**: White background, 1px border
- **Hover**: Subtle border color change
- **Selected**: Blue border

### Tables
- **Header**: Gray background, uppercase text
- **Row**: 44px height
- **Hover**: Subtle background change
- **Selected**: Blue background

### Inputs
- **Default**: Gray border
- **Focus**: Blue border
- **Error**: Red border
- **Disabled**: Gray background

### Badges
- **Success**: Green background
- **Warning**: Yellow background
- **Error**: Red background
- **Info**: Blue background
