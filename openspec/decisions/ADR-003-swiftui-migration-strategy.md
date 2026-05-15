# ADR-003: SwiftUI Incremental Migration Strategy

## Status
Accepted

## Context
The App is 100% UIKit with SnapKit. A full "big bang" rewrite is too risky.

## Decision
Adopt an **"Inside-Out" Incremental Migration Strategy**.

## Rationale
1. **Low Risk**: Start with simple leaf pages (Profile, Login) to establish the pattern.
2. **Hybrid State**: Use `UIViewControllerRepresentable` and `UIHostingController` to bridge legacy and modern components.
3. **Iterative Value**: Deliver modernized features while keeping the rest of the App functional.
4. **Learning Loop**: Refine the design system and TCA patterns on simpler pages before tackling the complex Player page.

## Consequences
- Requires temporary "bridge" code (converters, wrappers).
- Navigation logic will be complex during the hybrid phase (UIKit Nav vs SwiftUI NavigationStack).
- UI inconsistency might occur if the design system isn't strictly followed in hybrid views.
