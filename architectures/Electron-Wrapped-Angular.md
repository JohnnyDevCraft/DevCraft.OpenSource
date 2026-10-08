# Electron Wrapped Angular

## Purpose

Define the default architecture guidance for an Angular application packaged with Electron.

## When To Use

- The product is primarily Angular UI delivered as a desktop app through Electron.
- Desktop capabilities such as local filesystem access, native menus, or background processes are required.

## Core Principles

- Keep renderer and main-process responsibilities clearly separated.
- Treat IPC as an explicit contract boundary.
- Minimize privileged code exposure to the renderer.

## Recommended Structure

- Angular app for renderer UI.
- Electron main-process code in a clearly separate area.
- Preload layer for controlled IPC exposure.
- Shared contracts for IPC messages where helpful.

## Boundary Rules

- Renderer code should not access Node or OS capabilities directly unless explicitly exposed through preload.
- Main-process code should own privileged operations.
- IPC contracts should be narrow, typed, and versionable.

## Data and Integration

- Keep local file and OS integration behind application services in the main process.
- Validate IPC payloads on both sides when risk warrants it.
- Keep cross-process orchestration explicit and traceable.

## Testing

- Unit test renderer logic separately from main-process logic.
- Integration test IPC flows.
- Add desktop workflow tests for critical end-to-end behavior.

## Avoid

- Broad `window` API exposure from preload.
- Business logic duplicated in renderer and main process.
- Treating Electron as just a packaging step without security design.
