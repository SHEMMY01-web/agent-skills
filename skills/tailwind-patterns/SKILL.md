---
name: tailwind-patterns
description: Best practices for composing maintainable, responsive, high-performance Tailwind CSS utility classes and design tokens from agentic-awesome-skills.
---

# Tailwind CSS Patterns (Agentic Awesome Skills)

## Core Guidelines

### 1. Maintainable Class Ordering
Organize Tailwind utilities logically:
1. **Layout & Display:** `flex`, `grid`, `block`, `hidden`, `relative`, `absolute`, `overflow-hidden`
2. **Sizing & Spacing:** `w-full`, `max-w-6xl`, `h-auto`, `p-6`, `space-y-4`, `gap-3`
3. **Typography:** `font-sans`, `text-sm`, `font-bold`, `tracking-tight`, `leading-relaxed`
4. **Colors & Backgrounds:** `bg-white`, `text-slate-800`, `bg-gradient-to-br`
5. **Borders & Shadows:** `border`, `border-slate-200`, `rounded-2xl`, `shadow-md`
6. **Transitions & Pseudo-classes:** `transition-all`, `hover:border-blue-300`, `focus:ring-2`, `active:scale-95`

---

### 2. Responsive Breakpoint Discipline
- Design Mobile-First: `w-full sm:w-auto`, `flex-col sm:flex-row`, `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`.
- Avoid hardcoded pixel widths (`w-[342px]`) where responsive fractions or `max-w-*` fit naturally.

---

### 3. Component Extraction
- For repeated compound components (e.g. primary buttons, text inputs, card wrappers), maintain semantic class definitions in `index.css` (`@apply`) or reusable React component wrappers to eliminate drift.
