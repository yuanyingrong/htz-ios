# ADR-004: Player Actor Wrapper

## Status
Accepted

## Context
The core audio engine uses `FreeStreamer` (Objective-C/C), which is not thread-safe and is accessed via global singletons. This causes race conditions and UI freezing.

## Decision
Wrap the legacy `FreeStreamer` engine in a **Swift Actor** (specifically a `@globalActor`).

## Rationale
1. **Concurrency Safety**: Actors provide compiler-guaranteed data isolation.
2. **Modern API**: Exposes an async/await interface to the rest of the App.
3. **Decoupling**: Decouples audio logic from UIKit view controllers.
4. **Preservation**: Avoids the massive effort and risk of rewriting the low-level C/OC streaming logic.

## Consequences
- Requires bridging C-callbacks to Swift async continuations.
- UI must observe state via `AsyncStream` or `MainActor`-safe publishers.
- Potential performance overhead for high-frequency progress updates (mitigated by throttling).
