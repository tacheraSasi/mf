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


## Installation

Download the latest release for your platform from the
[releases page](https://github.com/tacheraSasi/mf/releases/latest), or use the direct
links below:

| Platform | Asset |
| --- | --- |
| macOS (Apple Silicon) | `mf-darwin-arm64.tar.gz` |
| macOS (Intel) | `mf-darwin-amd64.tar.gz` |
| Linux (x86_64) | `mf-linux-amd64.tar.gz` |
| Linux (ARM64) | `mf-linux-arm64.tar.gz` |
| Windows (x86_64) | `mf-windows-amd64.zip` |

Download, verify the SHA256 against `checksums.txt`, extract, and move the binary
onto your `PATH`:

### macOS / Linux

```sh
curl -L -o mf.tar.gz https://github.com/tacheraSasi/mf/releases/latest/download/mf-darwin-arm64.tar.gz
tar -xzf mf.tar.gz
sudo mv mf /usr/local/bin/
chmod +x /usr/local/bin/mf
mf --help
```

> Replace `mf-darwin-arm64.tar.gz` with the asset matching your platform.
> On macOS, the first run may be blocked by Gatekeeper; allow it under
> *System Settings → Privacy & Security*.

### Windows

Download `mf-windows-amd64.zip`, unzip it, and move `mf.exe` to a folder that's on
your `PATH` (e.g. `%USERPROFILE%\.bin`). Confirm with:

```cmd
mf --help
```

### Build from source

Requires [Zig 0.16.0](https://ziglang.org/download/).

```sh
git clone https://github.com/tacheraSasi/mf.git
cd mf
make build
./zig-out/bin/mf --help
```

## Usage

Work inside a directory that holds your Git repositories. `mf` reads and writes a
manifest (`mf.manifest.json`) in the current working directory.

```sh
# Generate a manifest from the Git repos already in the current directory
mf scan

# Clone a repo into the current directory and add it to the manifest
mf add https://github.com/<owner>/<repo>.git

# Show the status of every tracked repository
mf status

# Remove a tracked project (checks for uncommitted/unpushed changes first)
mf rm <project-dir>
# Remove and delete the working tree too
mf rm <project-dir> --purge

# Initialise an empty manifest in the current directory
mf init
```

Run `mf` with no arguments to see the full help text.

## Learning Zig

I'm building `mf` as my Zig learning project.

The goal is to understand the language by building a real tool that I'll use every day. Because of that, I won't be using LLMs to write code for this project. I'll rely on the Zig documentation, source code, and my own problem solving.

This is an AI-free zone.
