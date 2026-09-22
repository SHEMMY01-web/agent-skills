---
name: frontend-design
description: Enterprise UI/UX design direction, component layout structures, visual hierarchy rules, color composition, and modern aesthetic guidelines from agentic-awesome-skills.
---

# Frontend Design (Agentic Awesome Skills)

## Core Philosophy
Create distinctive, production-grade web interfaces with rich visual polish, intuitive ergonomics, and robust responsive layout discipline.

---

## 1. Visual Hierarchy & Spacing Architecture
- **Scale Hierarchy:** Establish high-contrast font scale (e.g. `text-3xl sm:text-4xl font-extrabold` for primary headers, `text-xs uppercase font-mono tracking-wider` for section tags, `text-sm sm:text-base` for body copy).
- **Container Sizing:**
  - Multi-column dashboards, registries, and data grids: `max-w-6xl` or `max-w-7xl` with `mx-auto`.
  - Focused form inputs / upload targets: `max-w-xl` or `max-w-2xl` with `mx-auto`.
- **Negative Space:** Use structured vertical rhythms (`space-y-6`, `space-y-8`, `space-y-12`) and padding scales (`p-4 sm:p-6 lg:p-8`).

---

## 2. Color Composition & Modern Surfaces
- **Curated Palettes:** Prefer tailored HSL / HEX shades over generic web colors.
- **Glassmorphism & Depth:**
  - Background: Semi-transparent backdrop blur (`bg-white/80 backdrop-blur-md` or `bg-slate-900/80`).
  - Subtle Borders: Fine borders (`border border-slate-200/80` or `border border-white/10`).
  - Multi-Layer Shadows: Soft ambient drop shadows (`shadow-xl shadow-slate-200/40` or `shadow-2xl shadow-indigo-950/20`).

---

## 3. Micro-Interactions & State Polish
- **Hover Transitions:** `transition-all duration-200 ease-in-out` on cards and buttons (`hover:border-blue-300 hover:shadow-md`).
- **Interactive Feedback:** Scale feedback on clicks (`active:scale-[0.98]`).
- **Loading & Empty States:** Never leave blank containers. Provide dedicated empty states with contextual illustrations, descriptive copy, and proactive action triggers.
