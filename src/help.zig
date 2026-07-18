/// returns the help text
pub fn HelpText() []const u8 {
    return
    \\
    \\mf -> workspace manifest CLI
    \\usage: mf <command> [options] [args]
    \\
    \\commands:
    \\  scan                      scan BASE and (re)build the manifest from existing git repos
    \\  add <git-url>             clone <git-url> into BASE, then refresh the manifest
    \\  status                    print a summary of every project tracked in the manifest
    \\  rm <dir>                  remove a project from the manifest (leaves the dir on disk)
    \\  nuke                      not implemented yet
    \\
    \\options:
    \\  --verbose                 print extra diagnostic output
    \\
    \\positional args:
    \\  <git-url>                 required by `add`
    \\  <dir>                     required by `rm`
    \\
    \\examples:
    \\  mf scan --verbose
    \\  mf add https://github.com/foo/bar.git
    \\  mf status
    \\  mf rm old-project
    \\
    \\the manifest file is `mf.manifest.json`, written into BASE.
    ;
}
