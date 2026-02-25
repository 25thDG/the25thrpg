# The 25th RPG — Game System

## Overview

A life-tracking app that gamifies 6 real-life skills into an RPG character sheet. Every skill has a level (1–100), and beyond 100 you earn mastery points. Your **Player Level** is the weighted average of all skills.

---

## The 6 Skills

| Skill | Input | Level 100 Target | Weight |
|---|---|---|---|
| Japanese | Study hours | 2,200 h | 1.2x |
| Wealth | Net worth (EUR) | €1,000,000 | 1.2x |
| Creation | Creative hours + project difficulty | ~1,000 h | 1.1x |
| Sport | Training hours + consistency | ~2,000 h | 1.0x |
| Mindfulness | Meditation minutes | 10,000 min (~167 h) | 1.0x |
| Social | Social hours | 750 h | 1.0x |

All skills use **sqrt scaling** — early levels come fast, later levels require exponentially more effort.

---

## Level Formulas

Every skill follows the pattern: `level = sqrt(input) / sqrt(target) × 100`, capped at 100.

### Japanese
- **Formula**: `sqrt(hours) / sqrt(2200) × 100`
- **Milestones**: Lv 2 ≈ 1h, Lv 10 ≈ 22h, Lv 25 ≈ 138h, Lv 50 ≈ 550h, Lv 100 = 2,200h

### Wealth
- **Formula**: `sqrt(netWorth / 1,000,000) × 100`
- **Milestones**: Lv 5 ≈ €2,500, Lv 10 ≈ €10,000, Lv 25 ≈ €62,500, Lv 50 ≈ €250,000, Lv 100 = €1,000,000
- **Note**: Only skill not based on time. Uses latest monthly net worth snapshot.

### Mindfulness
- **Formula**: `sqrt(minutes) / sqrt(10,000) × 100`
- **Milestones**: Lv 10 ≈ 100 min, Lv 25 ≈ 625 min, Lv 50 ≈ 2,500 min (~42h), Lv 100 = 10,000 min (~167h)
- **Note**: Fastest skill to max — only needs 167 hours.

### Sport
- **Formula**: `sqrt(hours) / sqrt(2000) × 100 + 10 × (trainedDays / 30)`
- **Consistency bonus**: Up to +10 levels for training every day in the last 30 days
- **Milestones** (without bonus): Lv 10 ≈ 20h, Lv 50 ≈ 500h, Lv 100 ≈ 2,000h
- **With max consistency**: Level 100 achievable at ~1,620h

### Social
- **Formula**: `sqrt(hours) / sqrt(750) × 100`
- **Milestones**: Lv 10 ≈ 7.5h, Lv 25 ≈ 47h, Lv 50 ≈ 188h, Lv 100 = 750h

### Creation
- **Formula**: `sqrt(hours) / sqrt(1000) × 100 + projectDifficultySum × 2`
- **Project bonus**: Each project's difficulty rating (1–5) adds +2 levels per point
- **Milestones** (without bonus): Lv 10 ≈ 10h, Lv 50 ≈ 250h, Lv 100 ≈ 1,000h
- **With projects**: A difficulty-5 project gives +10 levels, reducing the hours needed significantly

---

## Mastery System

Once a skill hits level 100, you start earning **mastery points**. Mastery requires continued effort beyond the level 100 threshold.

| Skill | Mastery rate |
|---|---|
| Japanese | +1 mastery per 200h beyond 2,200h |
| Wealth | +1 mastery per €250,000 beyond €1M |
| Mindfulness | +1 mastery per 1,000 min beyond 10,000 min |
| Sport | +1 mastery per 150h beyond 2,000h |
| Social | +1 mastery per 100h beyond 750h |
| Creation | +1 mastery per 100h beyond 1,000h |

Each mastery point adds **0.25** to your effective level (used in Player Level calculation).

---

## Player Level

Your overall Player Level is a **weighted average** of all 6 skill effective levels:

```
Player Level = floor(Σ(effectiveLevel × weight) / Σ(weights))
```

Weights: Japanese 1.2, Wealth 1.2, Creation 1.1, Sport 1.0, Mindfulness 1.0, Social 1.0 (total: 6.5)

Higher-weighted skills have more impact on your overall level.

---

## Activity Status

- **Active**: Has logged time in the last 30 days (or has positive net worth for Wealth)
- **Dormant**: No recent activity

Active skills show a red progress bar, dormant skills show a grey bar.

---

## App Features

### Player Tab
- **Player Level Panel** — Overall level, XP progress bar, top skill, active count, total mastery
- **Skill Radar Chart** — Hexagonal radar showing all 6 skills relative to each other (animated)
- **Skills Window** — Detailed rows per skill with level, mastery, progress bar, and hours remaining to next level

### Japanese Tab
- Lifetime hours vs 2,200h horizon
- Last 30 days + best 30-day period
- Category breakdown (reading, writing, speaking, etc.)
- Today's sessions — add, edit, delete

### Mindfulness Tab
- Lifetime minutes vs 10,000 min horizon
- Category breakdown by meditation type
- Last 30 days + best 30-day window
- Today's sessions — add, edit, delete

### Sport Tab
- Lifetime hours + training day count
- Category breakdown by sport type
- Last 30 days + best 30-day period
- Today's sessions — add, edit, delete via bottom sheet

### Social Tab
- Lifetime social hours + initiation split (you vs others)
- Last 30 days + best 30-day window
- Today's sessions — log who, type, duration via bottom sheet

### Creation Tab
- Lifetime creative hours across all projects
- Last 30 days + best 30-day window
- **Projects section** — Create, edit, complete, delete projects (each with difficulty 1–5)
- Today's sessions — log general time or time to specific projects

### Wealth Tab
- Current net worth display
- Circular progress toward €1M goal
- Historical net worth chart (monthly snapshots)
- All-time peak net worth
- Monthly snapshot input — add, update, delete

---

## Data Sources

All data stored in Supabase. Each feature tab logs sessions to its own table:

| Table | Used by | Key columns |
|---|---|---|
| `japanese_sessions` | Japanese | duration_minutes, category, date |
| `skill_sessions` | Mind, Sport, Social, Creation | skill_id (UUID), duration_minutes, category, date |
| `creation_sessions` | Creation (project-linked) | project_id, duration_minutes, date |
| `creation_projects` | Creation | name, status, difficulty (1–5) |
| `wealth_snapshots` | Wealth | net_worth_eur, month |

Skill UUIDs in `skill_sessions`:
- Mindfulness: `6e3b1f81-...`
- Sport: `e377b7af-...`
- Social: `a3870777-...`
- Creation: `1c955a16-...`

---

## Design

- Dark RPG theme with near-black backgrounds
- Red crimson accent (#C0392B)
- 7-tab bottom navigation: Player, JP, Mind, Wealth, Create, Social, Sport
- All text in uppercase for headers, monospace-inspired feel
- Staggered fade-in animations on skill rows
- Animated radar chart polygon fill
