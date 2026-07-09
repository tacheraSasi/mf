# mf

A simple workspace manifest CLI.

`mf` keeps a manifest of the Git repositories in a directory so you can recreate your workspace on any machine with a single command.

The manifest is the source of truth. Your local workspace can always be rebuilt from it.

## Goals

This is what I want `mf` to achieve over time:

- Scan a directory and generate a manifest from existing Git repositories.
- Recreate a workspace by cloning every repository from the manifest.
- Keep the manifest up to date as repositories are added or removed.
- Safely remove local repositories after checking for uncommitted or unpushed changes.
- Show the status of all tracked repositories.
- Let me clone repositories through `mf` and automatically update the manifest.
- Support nested workspaces, where one manifest can reference other manifests.
- Make it easy to rebuild my entire development environment on a new machine.
- Stay small, simple, and focused on workspace management.

---

## Learning Zig

I'm building `mf` as my Zig learning project.

The goal is to understand the language by building a real tool that I'll use every day. Because of that, I won't be using LLMs to write code for this project. I'll rely on the Zig documentation, source code, and my own problem solving.

This is an AI-free zone.