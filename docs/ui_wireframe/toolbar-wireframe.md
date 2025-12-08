# Annotation Editor - Toolbar Layout (Aligned to Tool Specification)

Two-tier toolbar (properties above, main below) aligned to current tool specs.

---

## Screen Layout

```
┌───────────────────────────────────────────────────────────────┐
│                           Canvas                              │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│ PROPERTIES BAR (changes per tool)                             │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│ MAIN BAR (fixed tool groups)                                  │
└───────────────────────────────────────────────────────────────┘
```

---

## Main Toolbar (fixed)

```
┌───────────────────────┬─────────────────────┬───────────────────────────┬─────────────────────────┬─────────────┐
│ Selection             │ Marking             │ Drawing                   │ Utility                 │ Actions     │
├───────────────────────┼─────────────────────┼───────────────────────────┼─────────────────────────┼─────────────┤
│ [Select]              │ [Freehand] [Highlight] [Blur] │ [Line] [Shape] [Text]     │ [Image] [Note] [Color Picker] │ [Undo] [Redo] [Settings] │
└───────────────────────┴─────────────────────┴───────────────────────────┴─────────────────────────┴─────────────┘
Notes:
- Color Picker shows a preset swatch list of predefined colors with alpha; optional custom picker for any color; affects next created object and selections when applicable.
- Settings menu houses global toggles (Snap to Grid, Alignment Guides, Rulers), layer list, keyboard help.
```

---

## Properties Toolbar by Tool

General layout: `[Tool Indicator] | Properties... | Quick Actions/Presets`

### Select Tool
```
[Select] | Object: [Type]  Pos: (x,y)  Size: w×h | Align [L][C][R][T][M][B] | Layer: [Bring F][Send B][Lock][Hide]
```

### Line Tool
```
[Line] | Color [■■■] | Width ─●──── | Arrowheads [Start][End] | Arrow Style [Open|Filled|Diamond|Circle]
       | Line Style [Solid|Dashed|Dotted] | Caps [Butt|Round|Square] | Presets [Thin][Medium][Thick]
```

### Shape Tool
```
[Shape] | Recent [Rect][Circle][Ellipse][Triangle] | All Shapes [Grid ▼]
        | Fill [■■■] | Stroke [■■■] | Stroke Width ─●────
```

### Text Tool
```
[Text] | Font [System ▼] | Size 16 | [B] [I]
       | Text Color [■■■] | Align [L][C][R][J] | Background [■■■]
```

### Number Tool
```
[Number] | Current: [n] | Circle Color [■■■] | Number Color [■■■]
         | Size ─●──── | Shape [Circle|Square|Rounded] | [Reset Counter]
```

### Freehand Tool
```
[Freehand] | Color [■■■] | Width ─●──── | Presets [Fine][Medium][Thick][Extra]
```

### Highlight Tool (freehand only)
```
[Highlight] | Color [■■■] (presets: Y/G/P/B/O) | Opacity ─●────
```

### Blur Tool (freehand only)
```
[Blur] | Pixelate Radius ─●────
```

### Note Tool
```
[Note] | Note Color [■■■ presets] | Text Color [■■■] (auto-contrast)
       | Font [System ▼] | Size ─●──── | [B] [I] | Align [L][C][R][J] | Arrow [On|Off]
```

### Image Tool
```
[Image] | Opacity ─●──── | Lock [ ] | Flip [H] [V]
```

---

## Responsive Rules
- Collapse labels to icons first; then wrap to second row; then offer overflow menu `[More ▼]`.
- Properties bar scrolls horizontally when needed on narrow widths.

---

## Quick Behavior Notes in UI
- Esc in any creation tool cancels in-progress draw; Undo removes last creation.
- Snap to Grid (8px, default off) and Alignment Guides (default on) toggles surfaced in Settings/quick menu.
- All tools except Select show rotate handle on selection; Line/Number omit rotate handle.
- Blur/Highlight are freehand paint only; no rectangle mode or feather control.
- Undo/Redo history is in-session only (not persisted). History depth: 100 actions.
