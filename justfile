# silt — Fluid Framework git-object primitives

# === ALIASES ===
alias b := build
alias t := test
alias f := format
alias l := lint
alias c := clean

# Default recipe
default:
    @just --list

# === STANDARD RECIPES ===

# Compile the project
build:
    gleam build

# Run tests
test:
    gleam test

# Format code
format:
    gleam format

# Type-check the project
lint:
    gleam check

# Remove build artifacts
clean:
    rm -rf build

# Full validation workflow
ci: format lint test build

alias pr := ci
