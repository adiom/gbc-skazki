# Repository Guidelines

## Project Structure & Module Organization
This repository is a minimal Game Boy demo written in RGBDS assembly. The core source lives in `main.asm`. Build outputs are a ROM (`demo.gb`) and an object file (`main.o`). Build rules are in `Makefile`, and a short overview is in `README.md`. Generated artifacts are ignored via `.gitignore`.

## Build, Test, and Development Commands
- `make`: assemble and link the ROM (`demo.gb`) using `rgbasm`, `rgblink`, and `rgbfix`.
- `make clean`: remove build artifacts (`main.o`, `demo.gb`).
- Run locally by opening `demo.gb` in a Game Boy emulator (e.g., SameBoy, BGB).

## Coding Style & Naming Conventions
- Assembly style: RGBDS syntax with `DEF` for constants and labels in `CamelCase` for routines (e.g., `WaitVBlank`, `ReadJoypad`).
- Data sections are grouped and named (e.g., `SECTION "Tiles"`, `SECTION "WRAM"`).
- Keep comments short and focused on intent, especially around hardware registers and routines.

## Testing Guidelines
There is no automated test framework in this repo. Verification is manual:
- Build the ROM with `make`.
- Open `demo.gb` in an emulator and confirm the background, sprite movement (D-pad), and A-button beep.

## Commit & Pull Request Guidelines
- Commit messages are short, imperative, and describe the change (e.g., "Add Game Boy demo sources and gitignore").
- PRs should include a brief description, emulator used for manual verification, and a screenshot or GIF if visuals changed.

## Dependencies & Tooling
- Requires RGBDS (`rgbasm`, `rgblink`, `rgbfix`). On macOS: `brew install rgbds`.
- Use the provided `Makefile` for consistent ROM builds.
