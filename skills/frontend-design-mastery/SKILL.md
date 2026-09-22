---
name: frontend-design-mastery
description: World-class frontend UI/UX design principles, responsive layout rules, typography hierarchies, and premium styling guidelines for modern web applications.
---

# Frontend Design Mastery & Aesthetic Excellence

This skill provides comprehensive rules and guidelines for crafting world-class, premium user interfaces that wow users with visual refinement, flawless responsiveness, and micro-interactions.

---

## 1. Core Visual Design Principles

### A. Layout & Container Hygiene
* **Never Squish Complex Multi-Column Views:** Dashboards, 3-column registries, and data tables must use wide containers (`max-w-6xl` or `max-w-7xl` or `w-full`), never narrow text wrappers (`max-w-2xl` / `max-w-md`).
* **Breathing Room & White Space:** Use balanced padding (`p-6 sm:p-8 lg:p-10`), generous section spacing (`space-y-8` / `space-y-12`), and consistent gap increments (`gap-4`, `gap-6`, `gap-8`).
* **Visual Hierarchy:** Dominant headings (`text-2xl sm:text-3xl font-extrabold`), subtle descriptive subheadings (`text-sm text-slate-500`), and distinct metadata badges (`font-mono text-[11px]`).

### B. Color Palette & Harmonious Accents
* **Avoid Flat Primaries:** Use curated, tailored shades:
  - Deep Authority Navy: `#031335` (Text, dominant headers, dark modes)
  - Royal Blue Accent: `#0357EE` (Primary CTA, active states, key highlights)
  - Metallic Gold Accent: `#D4AF37` (Special tags, badges, premium status)
  - Neutral Backgrounds: Slate-50 (`#F8FAFC`), Slate-100 (`#F1F5F9`), Pure White (`#FFFFFF`)
  - Semantic Statuses: Emerald-600 (`#059669` Safe), Amber-600 (`#D97706` Warning), Rose-600 (`#E11D48` Alert)

### C. Glassmorphism & Elevation
* Subtle border outlines: `border border-slate-200/80` or `border border-white/10`.
* Soft multi-layered shadows: `shadow-xl shadow-slate-200/50` or `shadow-sm hover:shadow-md`.
* Smooth rounded radii: `rounded-2xl` for cards, `rounded-3xl` for major feature containers, `rounded-full` for pills.

---

## 2. Interactive States & Micro-Interactions

* **Hover Transitions:** `transition-all duration-200 ease-in-out` with subtle scale or border highlight (`hover:border-blue-300 hover:shadow-md`).
* **Active Press Feedback:** `active:scale-[0.98]` or `active:scale-95` on interactive buttons.
* **Loading Skeletons & Spinners:** Clean pulsed skeletons or `Loader2 className="animate-spin"` for asynchronous actions.
* **Toast Feedback:** Never use blocking browser `alert()` or `confirm()`; use smooth slide-in notification toasts.

---

## 3. Responsive Breakpoints
* **Mobile (< 640px):** Single-column stacks, full-width inputs, touch-friendly tap targets ($\ge 44\text{px}$).
* **Tablet (640px – 1024px):** 2-column grids, compact metric bars.
* **Desktop ($\ge 1024px$):** 3-column layouts with dedicated sidebars and unobstructed content streams.
