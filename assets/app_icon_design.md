# PickleMatch App Icon Design

## Concept
A modern, clean app icon for PickleMatch featuring pickleball elements:

- **Primary Element**: Pickleball paddle (rounded rectangle shape)
- **Secondary Element**: Pickleball (circle with holes pattern)
- **Color Scheme**: 
  - Background: Gradient from blue (#2196F3) to green (#4CAF50)
  - Paddle: White with subtle shadow
  - Ball: Yellow/white (#FFF9C4)
  - Holes: Darker shade for contrast

## Design Layout
```
┌─────────────────┐
│  ╭─────────╮    │
│ ╱           ╲   │
│╱   ●   ●   ╲   │
││   ●   ●   │   │
│╲   ●   ●   ╱   │
│ ╲_________╱    │
│     ████       │
│     ████       │
│     ████       │
└─────────────────┘
```

## Icon Sizes Needed

### Android (mipmap directories):
- mdpi: 48x48px
- hdpi: 72x72px  
- xhdpi: 96x96px
- xxhdpi: 144x144px
- xxxhdpi: 192x192px

### iOS (AppIcon.appiconset):
- 20x20@1x, @2x, @3x
- 29x29@1x, @2x, @3x
- 40x40@1x, @2x, @3x
- 60x60@2x, @3x
- 76x76@1x, @2x
- 83.5x83.5@2x
- 1024x1024@1x

## Implementation Notes
- Use vector graphics (SVG) as base for scaling
- Ensure readability at smallest sizes (20x20)
- Maintain brand consistency with app theme
- Test visibility on various backgrounds