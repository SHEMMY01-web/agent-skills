---
name: platformer-level-design
description: Master platformer level design guide based on Ryan Barone (iD Tech), Diorgo Jonkers, Nintendo's Kishōtenketsu, Mark Brown's GMTK, and Celeste/Mario spatial design methodologies. Use when designing, pacing, structuring, balancing, or reviewing platformer level layouts, jump physics metrics, hazard timing windows, enemy encounter densities, strategic collectible positioning, and sub-room traversal loops.
---

# Master Platformer Level Design Architecture

A comprehensive, mathematically grounded manual for 2D and 2.5D action/precision platformer level design. Incorporates design frameworks from Nintendo (*Super Mario* series), Maddy Thorson (*Celeste*), Mark Brown (*Game Maker's Toolkit*), and Gamasutra/Game Developer architectural analyses.

---

## 1. Core Architectural Frameworks & Pedagogical Philosophy

### 1.1 Nintendo's Kishōtenketsu (4-Act Level Progression)
Popularized by Koichi Hayashida and Shigeru Miyamoto, this structural philosophy introduces, develops, tests, and resolves mechanics without verbal tutorials or intrusive UI hand-holding.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     1. KI       │ ──> │    2. SHŌ       │ ──> │     3. TEN      │ ──> │    4. KETSU     │
│ (Introduction)  │     │  (Development)  │     │    (The Twist)  │     │  (Resolution)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
 • 100% Safe Zone        • Add Low Stakes        • Surprising Combo      • Mastery Test
 • Zero Death Penalty    • Introduce Timing      • Inverts Intuition     • Rewarding Exit
 • Organic Discovery     • Simple Obstacles      • High Tension          • Victory Milestone
```

1. **Ki (Introduction / Safety)**:
   * Introduce the single new mechanic (e.g. steam geyser, crumbling block, gravity inverter) in a completely safe, low-stakes sub-room or ledge.
   * Failure has zero death penalty (e.g. falling drops player back to starting ledge).
2. **Shō (Development / Variation)**:
   * Re-introduce the mechanic in a standard traversal context with moderate stakes (e.g. cross a small gap, time a jump over standard hazard).
   * Solidifies muscle memory and establishes consistent rhythm.
3. **Ten (The Twist / Complication)**:
   * The "surprise" phase. Combine the mechanic with an orthogonal system (e.g. steam geyser + falling ash block, or laser rhythm grid + pursuing Hunter AI).
   * Forces the player to apply the mechanic under cognitive load or in an inverted, counter-intuitive spatial orientation.
4. **Ketsu (Resolution / Mastery & Climax)**:
   * High-intensity culmination requiring flawless execution of the mastered skill (e.g. gauntlet or pre-boss gate sequence).
   * Concludes with an emphatic reward, lore pickup, or celebratory level transition.

---

## 2. Spatial Algorithms, Jump Physics Metrics & Grid Alignment Rules

### 2.1 Fundamental Jump Trajectory & Physics Derivation
Never guess jump physics values arbitrarily. Derive exact gravity ($g$) and jump impulse velocity ($v_0$) from desired maximum jump height ($h$) and time-to-peak ($t_{\text{peak}}$).

$$\text{Gravity } (g) = \frac{2h}{t_{\text{peak}}^2} \qquad \text{Initial Jump Velocity } (v_0) = \sqrt{2gh} = g \cdot t_{\text{peak}}$$

#### Parabolic Jump Arc Equation
The height $y$ at horizontal distance $x$ traveled at constant run speed $v_x$:

$$y(x) = \left(\frac{v_0}{v_x}\right) x - \frac{g}{2 v_x^2} x^2$$

#### Maximum Horizontal Traversal Span ($d_{\text{max}}$)
$$d_{\text{max}} = v_x \cdot (2 \cdot t_{\text{peak}}) = 2 v_x \sqrt{\frac{2h}{g}}$$

```
Height (y)
  ▲                     Apex: (d_max / 2, h)
  │                            ╭───╮
  │                        ╭──╯     ╰──╮
  │                     ╭─╯             ╰─╮
  │                  ╭──╯                 ╰──╮
  │               ╭──╯                       ╰──╮
  │           ╭──╯                               ╰──╮
──┴───────────┴──────────────────────────────────────┴────────► Horizontal (x)
         Start Ledge                              Landing Ledge
         ◄────────────────── d_max ──────────────────►
```

### 2.2 Jump Asymmetry & Responsive Game Feel (Celeste / Mario Rules)
* **Asymmetric Gravity (Snappy Descent)**:
  * Upward ascent: $g_{\text{rise}} = g$
  * Downward descent: $g_{\text{fall}} = 1.6 \sim 2.0 \cdot g_{\text{rise}}$ (prevents "floatiness" and accelerates return to player agency).
* **Variable Jump Height (Early Release Cut)**:
  * If the player releases the jump button while $v_y < 0$ (ascending), immediately clamp vertical velocity: $v_y = \max(v_y, v_0 \cdot 0.35)$.
* **Input Forgiveness Windows**:
  * **Coyote Time**: $80 - 120\text{ms}$ ($5 - 8\text{ frames}$ at 60 FPS) after stepping off a platform edge where jump input is still registered as valid ground jump.
  * **Jump Buffering**: $100 - 150\text{ms}$ ($6 - 10\text{ frames}$) prior to landing where pressing jump buffers the action to execute instantly on first contact frame.
  * **Corner Snapping / Ledge Forgiveness**: If the player strikes a ceiling corner or platform edge within $4 - 8\text{px}$, push player around the geometry rather than stopping velocity.

### 2.3 Grid Alignment & Platform Dimensioning Rules

| Parameter | Recommended Dimension | Design Constraint & Rationale |
| :--- | :--- | :--- |
| **Grid Unit Size** | $16\times 16\text{px}$ or $24\times 24\text{px}$ or $32\times 32\text{px}$ | All tiles, collision masks, and ledges must lock to grid units to prevent sub-pixel snagging. |
| **Hero Hitbox Width** | $0.8 \sim 1.0\text{ Grid Units}$ ($24-32\text{px}$) | Narrower than visual sprite by $15-20\%$ for forgiving hazard navigation. |
| **Hero Hitbox Height** | $1.4 \sim 1.8\text{ Grid Units}$ ($44-56\text{px}$) | Standard human proportion. |
| **Corridor Ceiling Clearance** | $\text{Hero Height} + 1.25\text{ Tiles}$ ($\ge 72\text{px}$) | Prevents accidental head-bumping during standard running jumps. |
| **Standard Platform Thickness** | $1\text{ Tile } (24-32\text{px})$ up to $3\text{ Tiles } (72-96\text{px})$ | Thin platforms denote drop-through or lightweight scaffolds; thick denotes structural bedrock. |
| **Comfort Jump Distance ($d_{\text{safe}}$)** | $0.65 \sim 0.75 \cdot d_{\text{max}}$ | Standard traversal gaps. Never require $100\% \ d_{\text{max}}$ on mandatory main paths. |
| **Precision Skill Gap ($d_{\text{hard}}$)** | $0.88 \sim 0.95 \cdot d_{\text{max}}$ | Reserved for optional branches, secret collectibles, or Ten/Ketsu climax gauntlets. |

---

## 3. Strategic Collectible Placement with Precise Mathematical Metrics

Collectibles serve three distinct architectural functions: **Instructional Breadcrumbs**, **Progression Gates**, and **Mastery Milestones**.

```
                           [TIER 3: SECRET / MASTERY]
                           • High Risk, Blind Alcoves
                           • Requires Maximum Jump Mechanics
                           • R = C * ΔH * P_death
                                      │
                                      ▼
                       [TIER 2: PROGRESSION KEYS]
                       • Mandatory / Branch Paths
                       • Guarded by Hunter Mechs & Hazards
                       • 15-25% Extra Traversal Effort
                                      │
                                      ▼
    [TIER 1: BREADCRUMBS] ───────────────────────────> [EXIT ELEVATOR]
    • Guides Eye along Safe Arc (y = y0 - 4h*t(1-t))     (Requires 100% Tier 2 Keys)
```

### 3.1 The 3-Tier Collectible Hierarchy

| Tier | Category | Example Asset | Placement Rule | Spatial Math & Trajectory |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1** | **Breadcrumb Guides** | Trailing Gold Coins | Parabolic Jump Arcs & Conveyor Lanes | Sample points along: $y(t) = y_0 - 4h \cdot t(1-t)$ for $t \in [0, 1]$. Informs player of ideal jump apex and safe landing zone. |
| **Tier 2** | **Progression Keys** | Solar Canisters, Power Cells, Filter Cores | Guarded Alcoves, Hazard Apexes, Scaffold Peaks | Placed at $y_{\text{apex}} = y_{\text{hazard}} - (0.85 \cdot h_{\text{max}})$ or behind a mandatory sub-challenge requiring route planning. |
| **Tier 3** | **Mastery Secrets** | Secret Lore Disks, Overclock Chips | Negative Space Pockets, Rebound Alcoves | Requires multi-mechanic combos (e.g. wall-slide cancel $\to$ geyser launch $\to$ sprint dash). |

### 3.2 Risk/Reward Metric Equation
The value and gratification ($R$) of a collectible must scale proportionally with risk of failure:

$$R = K \cdot \left( \Delta H_{\text{fall}} \times P_{\text{damage}} \times \frac{d_{\text{gap}}}{d_{\text{max}}} \right)$$

* If a collectible is located over a lethal smog pit or instant-death hazard ($P_{\text{damage}} = 1.0$), it must be clearly visible from a stable viewing platform before the jump is attempted.

---

## 4. Verticality, Sightlines & Negative Space Principles

### 4.1 The 3-Tier Vertical Layering Model
Every well-composed platformer level contains 3 functional vertical strata:

```
▲ Height
│ ┌────────────────────────────────────────────────────────┐  HIGH SCAFFOLD / CRANE GIRDERS
│ │ [Tier 3: High Walkways] - Optional secrets, shortcuts   │  • Positive space: 20%
│ ├────────────────────────────────────────────────────────┤  MAIN TRAVERSAL ARTERY
│ │ [Tier 2: Intermediate Catwalks] - Standard path & flow  │  • Positive space: 40%
│ ├────────────────────────────────────────────────────────┤  ABYSS / HAZARD FOUNDATION
│ │ [Tier 1: Industrial Floor / Hazard Pits] - High danger │  • Positive space: 15% (85% Void/Pit)
└─┴────────────────────────────────────────────────────────┘
```

### 4.2 Sightlines & The "No Blind Leaps" Rule
1. **Rule of Thirds Viewing Frustum**:
   * The player's active camera center must offset horizontally in movement direction by $+120\text{px} \sim +180\text{px}$ ("lookahead").
   * Upcoming hazards or landing targets must enter the camera viewport at least $1.2\text{s}$ before the hero reaches them at maximum running speed:
     $$d_{\text{lead}} \ge v_{\text{run}} \times 1.2\text{s}$$
2. **Preventing Blind Drops**:
   * Never force the player to drop downward into off-screen negative space.
   * If a downward drop is required, use:
     * Trailing coins tracing the exact downward drop path.
     * Soft down-pan camera triggers when ducking or standing near ledge for $> 0.4\text{s}$.
     * Environmental lighting cues (e.g. glowing landing light or steam vent illuminating platform edge).

### 4.3 Positive vs. Negative Space Ratios
* **Standard Platforming Zones**: $30-35\%$ Positive Space (solid geometry/walkways) vs. $65-70\%$ Negative Space (open air, background depth, maneuverability volume).
* **Claustrophobic Gauntlets (Sector 4 / Shafts)**: $50\%$ Positive Space vs. $50\%$ Negative Space (forces precise wall-jumps and narrow clearances).

---

## 5. Enemy Placement Density Relative to Jump Obstacles

Enemies in platformers are not merely combat targets—they are **dynamic kinetic obstacles** designed to interrupt sprint momentum and force spatial calculation.

```
       [Player Jump Arc]
       ╭─────────────╮
       │             │
───────┴─           ─▼─────────────────
  Ledge A             [Safe Reaction Zone] ──> [Enemy Patrol]
                      ◄───── >= 140px ────►
```

### 5.1 Spatial Rules for Enemy Placement
1. **The Landing Reaction Deadzone**:
   * Never place an enemy hitbox directly on the exact landing pixel of a maximum-range jump.
   * Always provide a minimum reaction buffer of $\ge 140\text{px}$ ($0.45\text{s}$ at $300\text{px/s}$) from platform edge to enemy patrol boundary, allowing the player to land, assess, and execute an attack or dodge.
2. **Threat Density Benchmarks**:
   * **Low-Stress / Exploration Zones**: 1 enemy per $1200 - 1600\text{px}$ ($\approx 4-5\text{s}$ traversal).
   * **Medium Platforming Sections**: 1 enemy per $600 - 800\text{px}$ ($\approx 2-3\text{s}$ traversal).
   * **High-Tension Combat Arena**: $2-3$ enemies per $400 - 600\text{px}$ deployed on staggered vertical tiers.
3. **Projectile Enemy Placement**:
   * Turrets or ranged snipers must be positioned at elevated vantage points where their projectile line-of-sight is telegraphed (e.g. laser sightline beam or charging glow for $\ge 0.6\text{s}$ prior to discharge).

---

## 6. Checkpoints vs. Difficulty Spikes

### 6.1 Checkpoint Spacing & Cadence Matrix

| Game Style / Level Section | Target Time Between Checkpoints | Placement Anchor Location |
| :--- | :--- | :--- |
| **Standard Action Platformer (Green City)** | $45 - 75\text{ seconds}$ | Immediately following a major hazard gauntlet; before boss gates. |
| **Precision Puzzle Screen (*Celeste* Style)** | $10 - 20\text{ seconds}$ | On every entrance platform of a discrete sub-room screen. |
| **Boss Encounter Floor** | $0\text{ seconds}$ (Pre-Boss Gate) | Full health/energy replenish station directly outside the boss arena gate. |

### 6.2 The Tension / Relief Curve
* **Difficulty Spike Rule**: After every high-intensity climax (e.g. crumbling block avalanche over rising smog), the level MUST provide an immediate **Valley of Relief**:
  * Safe resting platform.
  * Checkpoint activation anchor.
  * Ambient lore terminal, NPC dialogue, or coin fountain.
* Never chain two maximum-difficulty gauntlets back-to-back without a relief valley.

---

## 7. Sub-Room Traversal & Pacing Cycles

Large platformer levels must be decomposed into discrete **Sub-Rooms / Micro-Challenges** connected by transition corridors.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                 SUB-ROOM ANATOMY                                       │
│                                                                                        │
│  [PHASE 1: OBSERVATION]       [PHASE 2: EXECUTION GAUNTLET]     [PHASE 3: TRANSITION]  │
│  • Safe Spawn Ledge           • Timed Geysers / Crumbling Plats • Exit Gate / Elevator │
│  • Full Sightline of Room     • Chasing Hunter AI / Lasers      • Checkpoint Anchor    │
│  • Zero Immediate Threats     • Dynamic Skill Execution         • Reward / Objective   │
│                                                                                        │
│  ◄──── 200 - 300px ───►       ◄──────── 800 - 1400px ────────►  ◄──── 200 - 300px ───► │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### 7.1 The 3-Phase Sub-Room Topology
1. **Phase 1: Observation Ledge (Cognitive Setup)**:
   * A safe zone where the player can come to a full stop without threat of incoming damage.
   * Provides an unobstructed camera view of the upcoming challenge, allowing the player to observe hazard cycles (e.g. steam vent rhythm: $0.9\text{s}$ burst, $1.1\text{s}$ rest).
2. **Phase 2: Execution Gauntlet (Kinetic Engagement)**:
   * The active platforming problem: requires rhythmic timing, jump apex control, enemy dodging, or gadget interactions.
   * Traversal length: $800 - 1400\text{px}$ ($\approx 3-6\text{ seconds}$ of focused execution).
3. **Phase 3: Exit Buffer / Milestone Gateway (Resolution)**:
   * A secure landing zone featuring the sub-room's reward (Energy Canister, keycard, or checkpoint anchor).
   * Transitions cleanly into the next observation ledge.

### 7.2 The 3-Tier Pacing Time Cycle (Micro, Meso, Macro)

```
MACRO CYCLE: Complete Sector Floor (90 - 180s)
 ├── MESO CYCLE 1: Introductory Sub-Room (Ki/Shō) ─────── [25 - 35s]
 ├── MESO CYCLE 2: Complex Puzzle Gauntlet (Ten) ──────── [35 - 50s]
 └── MESO CYCLE 3: Gatekeeper Gauntlet & Climax (Ketsu) ─ [30 - 45s]
      └── MICRO CYCLES: Single Jump / Hazard Rhythm ───── [2.0 - 4.5s each]
```

* **Micro-Cycle ($2.0 - 4.5\text{s}$)**: A single jump across a hazard gap or dodging a patrolling enemy.
* **Meso-Cycle ($25 - 50\text{s}$)**: A complete sub-room challenge from Observation Ledge to Exit Gateway.
* **Macro-Cycle ($90 - 180\text{s}$)**: The entire floor traversal from elevator entry to elevator exit.

---

## 8. Level Sizing & Spatial Math Matrix

Use these exact dimensional benchmarks when building and reviewing levels in the engine:

### 8.1 Spatial Metrics Table

| Metric Parameter | Value in Pixels | Real-Time Traversal Duration |
| :--- | :--- | :--- |
| **Standard Hero Run Speed ($v_x$)** | $300 - 340\text{px/s}$ | Ground baseline velocity. |
| **Standard Jump Height ($h$)** | $120 - 140\text{px}$ ($3.75 - 4.5\text{ Tiles}$) | Peak elevation at $t_{\text{peak}} = 0.38\text{s}$. |
| **Maximum Jump Span ($d_{\text{max}}$)** | $240 - 270\text{px}$ ($7.5 - 8.5\text{ Tiles}$) | Full forward sprint jump span. |
| **Standard Level Width** | $3600 - 4800\text{px}$ | $\approx 12-16\text{ Screen Widths}$ ($120-180\text{s}$ pacing). |
| **Standard Level Height** | $900 - 1200\text{px}$ | Allows 3-4 vertical platform tiers. |
| **Vertical Shaft Width** | $1200 - 1600\text{px}$ | Designed for ascending wall-jump routes. |
| **Boss Arena Width** | $2200 - 2800\text{px}$ | Accommodates mobile boss leap ranges + pre-boss security gate. |
| **Hazard Burst Cycle Periodicity** | $2.0 - 2.6\text{s}$ ($0.8-1.0\text{s}$ active) | Optimal rhythm for human observational reaction time. |
