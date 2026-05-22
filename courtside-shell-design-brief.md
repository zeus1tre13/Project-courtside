# Courtside — App Shell Redesign Brief

**For:** Claude Design (claude.ai/design)
**From:** Courtside iOS team
**Date:** 2026-05-22

---

## What this is

Courtside is an iPhone app for volunteer scorers and coaches to track high
school basketball games. Its **game flow** — the live-game scorer, post-game
recap / box score / shot chart, roster scan, game setup, period transition,
assist prompt, and team analytics — was already redesigned and shipped under
the **"Direction B · Player-First"** handoff. Those screens now use a warm,
paper-toned light theme with jersey-disc avatars and a condensed display
typeface.

What's left is the **app shell** — the launch screen, team management, roster
management, and settings. These screens were never part of the original design
and still use the old look: a bright orange (`#FF5E1A`), system-default
`Form`/`List` styling, and a dark header. They now clash with the redesigned
game flow.

**Please design the shell screens below so they match the Direction B system.**
Same medium as the original handoff: pixel-accurate **HTML/CSS/JS mockups**,
iPhone portrait, light mode. A coding agent will implement them in SwiftUI
afterward.

---

## The design system to match

These tokens are already live in the app (`View/Shared/Theme.swift`). Every
shell screen must use them — do not introduce new colors or the old orange.

### Colors

```
/* Surfaces — warm paper */
--bg-app:      #F4F2EC   /* canvas backdrop */
--bg-stage:    #FBFAF6   /* screen background */
--bg-card:     #FFFFFF   /* elevated card */
--bg-soft:     #ECEAE3   /* subtle chip / pill */
--bg-softer:   #F1EFE8
--line:        #E2DED5   /* hairline border */
--line-strong: #C8C3B6

/* Ink */
--ink:      #14141A
--ink-2:    #2A2A33
--ink-mute: #6B6B73
--ink-dim:  #9A9AA3

/* Identity */
--brand:      #E8492A   /* basketball-leather red-orange — THE accent */
--brand-soft: #FBE7DF
--brand-ink:  #B8341A
--home:       #1D6CFF   /* your team — cool blue */
--home-soft:  #E3ECFF
--away:       #E8492A   /* opponent — warm */

/* Semantic */
--made:   #1AA46E   /* win / positive */
--danger: #DC2626   /* destructive only — delete, end */
--amber:  #E89B2A   /* warning */
```

### Typography

| Family | Use |
|---|---|
| **Big Shoulders Display** (700–900) | Scores, screen titles, section headers, large numerics |
| **Geist** (400–700) | UI body, buttons, labels |
| **Geist Mono** (500–700) | Jersey numbers, dates, statistical numerics |

### Sizing, spacing, corners

- Standard horizontal page padding: **14pt**
- Card radius: 12 (chips/small) · 14 (cards) · 18–22 (sheets/hero blocks)
- Card padding: 10–16pt; row gap 6pt
- Title scale: section titles ~22–26pt display; screen kickers 11pt uppercase, 0.14em tracking

### Established components (reuse them — already built in SwiftUI)

- **Jersey** — a number on a colored disc (team color). Sizes 22–56. A dimmed
  gray variant exists for bench/inactive. This replaces every generic avatar.
- **ScreenChrome** — the in-app top bar: 48pt tall, three slots
  (left / center / right). Used on every screen.
- **Wordmark** — small "COURTSIDE" lockup: a basketball-circle glyph + the word
  in the display face, brand-colored. Goes in the chrome center.
- **SectionLabel** — uppercase small-caps label, 11pt, 0.14em tracking, ink-dim.
- **Chip** — soft rounded pill for filters and tags.
- **Card** — white surface, 1px `--line` border, 12–14 radius. The redesign
  uses cards instead of system `List`/`Form` grouping.

**General rule:** no iOS system `Form` or grouped `List` look. Everything is
warm-paper background + white cards + the components above.

---

## Screens to design

Eight screens. For each: what it's for, what data/actions it carries today,
and notes on intent. Design the default state **and** the empty state where one
is called out.

### 1. Home / launch screen

The first screen on open. Current content:

- A dark header band with the "Courtside" wordmark, the tagline
  *"94 FEET. EVERY INCH, COVERED."*, a faint half-court diagram watermark, and
  a settings gear button.
- **New Game** — primary action button.
- **Teams** — a row that navigates to the team list, showing a team count.
- **Recent Games** — a list of finished games; each row: "vs {Opponent}", the
  date, and the final score (e.g. `63–45`). Swipe to delete.
- A faint Courtside watermark in the lower third.

Intent: this is the app's front door — make New Game unmistakably the primary
action. Recent games should feel tappable and scannable (a win/loss read would
help). Decide whether to keep the dark header band or move to the warm-paper
treatment used elsewhere. **Empty state:** no teams and no games yet.

### 2. Teams list

Reached from Home → Teams. Current content:

- Chrome: back button, "Teams" title, "+" add-team button.
- A list of team rows: a color accent bar, an initials disc, the team name, and
  a player count ("12 players").
- **Empty state:** "No Teams — Add your first team to get started."

Intent: team rows should use the Jersey-style disc / team color. Tapping a row
opens Team detail.

### 3. Team detail

Reached from Teams list. Current content:

- The team name and its win–loss record (e.g. `9-3`).
- **Roster** — navigates to the roster (shows player count).
- **Analytics** — navigates to team analytics (already redesigned).
- **Games** — list of that team's finished games (vs opponent, date, score,
  win/loss color). Empty: "No games yet."
- An **Edit** action (opens the team form).

Intent: a team "home." A record/identity header treatment would be nice — think
the team's color, initials disc, W-L. Roster and Analytics are the two nav
destinations.

### 4. Team form (new / edit team)

A sheet. Current fields:

- **School / Organization** name (required)
- **Team name** — e.g. "Varsity", "JV" (optional)
- **Team color** — pick one of 12 swatches.

Intent: a short, friendly create/edit form. Cancel / Save (or Create) actions.
Show a live preview of the team's jersey disc in the chosen color if it reads well.

### 5. Roster

Reached from Team detail → Roster. Current content:

- **Active** players section and an **Inactive** players section.
- Player rows: jersey number + full name. Tapping a row edits the player.
- A "+" menu offering **Add Player** and **Scan Roster** (the scan flow is
  already redesigned — match it).
- Swipe to delete. **Empty state:** "No Players — Add players to your roster."

Intent: rows should use the Jersey disc. Active vs Inactive grouping should be
clear. This is the screen coaches use most outside of games.

### 6. Player form (add / edit player)

A sheet. Current fields:

- **First name**, **Last name**, **Jersey number** (number pad).
- An **Active** toggle (shown only when editing).

Intent: short create/edit form. A live jersey-disc preview of the entered
number would be a nice touch. Cancel / Add (or Save).

### 7. Settings

A sheet. Current content:

- **Gym Mode** toggle — "High-contrast, light appearance for bright gyms."
- **Prompt for Assists** toggle — "After a made 2PT/3PT, ask who passed."
- Links: **Contact Support**, **Privacy Policy**.
- **Version** number row.

Intent: a compact settings screen in the warm-paper card style. Group the two
toggles together; links and version below.

### 8. Splash

The launch image shown for ~1.2s on cold start. Currently a full-bleed image.

Intent: a clean brand moment — the Courtside wordmark / basketball mark on the
warm-paper (or brand) background. Static, no interaction.

---

## Deliverable

Same format as the original "Courtside Review" handoff:

- HTML/CSS/JS mockups, iPhone portrait (≈402×874), light mode, on the
  warm-paper canvas.
- Reuse the shared atoms (Jersey, Chip, ScreenChrome, Wordmark, SectionLabel)
  so the coding agent can map 1:1 to the existing SwiftUI components.
- One file per screen (or one review file linking them), plus a short README
  describing each screen and any new components introduced.
- Call out every empty state and any loading state.

When the mockups are exported as a handoff bundle, hand it back and the coding
agent will implement these screens in SwiftUI — replacing `HomeView`,
`TeamListView`, `TeamDetailView`, `TeamFormView`, `RosterView`,
`PlayerFormView`, `SettingsView`, and the splash.
