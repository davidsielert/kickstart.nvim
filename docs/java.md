# Java development

Open a `.java` file in a Maven or Gradle project.
The first import downloads dependencies and builds the project index; wait for JDT LS to report ready.
The config uses `nvim-java`, which downloads and manages its own JDT LS, Java debug adapter, Java test extension, and Lombok agent.
Use Telescope for file search and Oil for directory browsing.
Press `<Space>sf` to find files, `-` to open the current file's parent directory, or `<Space>o` for a floating Oil browser.
Opening a directory directly, including `nvim .`, uses Oil.

## Everyday keys

`<leader>` is Space.
Java editing and test mappings become available when the language server attaches.
Press `<Space>j` for the menu or `<Space>?` for the cheatsheet.

| Keys | Action |
| --- | --- |
| `gd`, `gr`, `gI`, `K` | Definition, references, implementation, documentation |
| `<Space>rn`, `<Space>ja` | Rename, code actions including constructor/getter/equals generation |
| `<Space>f` | Format buffer or visual selection using JDT LS |
| `<Space>uf` | Toggle format on save for this buffer |
| `<Space>ji` | Organize imports |
| `<Space>jv`, `<Space>jV` | Extract variable, or every occurrence of it, also in visual mode |
| `<Space>jc`, `<Space>jf` | Extract constant or field, also in visual mode |
| `<Space>jm` in visual mode | Extract method |
| `<Space>jk`, `<Space>jI` | Signature help, toggle parameter hints |
| `<Space>jo` | Toggle class/method outline |
| `<Space>jr`, `<Space>jx` | Run a discovered main class without breakpoints, stop it |
| `<Space>jg`, `<Space>jP` | Toggle the run log, edit run profiles (JVM and program arguments) |
| `<Space>jd` or F5 | Choose a main class to debug, or continue |
| `<Space>jt`, `<Space>jT`, `<Space>jA` | Run nearest JUnit test, test class, or all tests |
| `<Space>jn`, `<Space>jN` | Debug nearest JUnit test or test class |
| `<Space>jw` | View the last test report |
| `<Space>jp`, `<Space>js` | Compile workspace, reload build configuration |
| `<Space>jS` | Change the project JDK |
| `<Space>jb`, `<Space>jB` | Toggle breakpoint, set conditional breakpoint |
| F10, F11, F12 | Step over, into, out |
| `<Space>je` | Evaluate expression or visual selection |
| `<Space>ju`, `<Space>jR` | Toggle debugger panels, debugger REPL |
| `<Space>jq`, `<Space>jl` | Terminate session, repeat last session |

Debugger panels open on launch and stay open after exit so output remains readable.
`<Space>jr` runs the application in nvim-java's own log window instead of the debugger.
Test output appears in the debugger REPL; `<Space>jw` opens a pass/fail report for the last test run.

## JDKs and project settings

The server runs on JDK 21 through 25.
If none is installed, nvim-java downloads a JDK for the server on first use.
On this Mac, JDK 25 runs the server and JDK 11 is available for coursework.
The config discovers macOS JDKs 8, 11, 17, 21, and 25 through `/usr/libexec/java_home`.
Maven and Gradle define the project's language level; the editor does not rewrite the build files.
Java 11 is the default for standalone files when installed.

To override discovery, set `JDTLS_JAVA_HOME` for the server and `JAVA11_HOME`, `JAVA17_HOME`, `JAVA21_HOME`, or `JAVA25_HOME` for project runtimes before launching Neovim.
`JAVA8_HOME` is also supported.
These variables are also the explicit configuration method on Linux.
Changing them requires restarting Neovim.
Use `:JavaSettingsChangeRuntime` or `<Space>jS` to change the runtime for an unmanaged project.
Terminal Maven/Gradle commands still use your shell's `JAVA_HOME`; the editor does not change it globally.

Project roots prefer Maven/Gradle wrappers, Gradle settings, and Git roots, then build files.
For a multi-module Maven build, put the Maven wrapper at the aggregate root.
The JDT index is keyed by the directory Neovim was started in, so start Neovim from the project directory.
Lombok support uses the agent nvim-java downloads.
Spring Boot tools are turned off; set `spring_boot_tools.enable` in `lua/custom/java.lua` to use them.

For custom launch arguments, environment variables, or remote attach configurations, use the project's `.vscode/launch.json` with `type: "java"`.
Start Neovim from the project directory; DAP reads `.vscode/launch.json` relative to the current working directory when you start a session.

## Maintenance and verification

Run `:checkhealth custom.java` for JDK, package, and parser checks.
nvim-java installs its tools under Neovim's data directory in `nvim-java/packages` the first time a Java file is opened.
Use `:lsp restart jdtls` for a stuck server, `:JavaBuildCleanWorkspace` for a corrupt index, and `<Space>js` after build-file changes.
`:LspLog` contains protocol errors; nvim-java logs to `nvim-java.log` in Neovim's state directory.

From this config directory, run:

```sh
nvim --headless -i NONE '+luafile scripts/verify-java.lua'
```

The check requires Maven, JDK 11, installed plugins/tools, and network access for uncached Maven dependencies.
It creates a temporary Java 11 Maven project, runs Maven tests, then verifies real LSP responses, diagnostics, formatting, outline data, breakpoint stops, expression evaluation, application output, and JUnit class/method execution through Neovim.
It exits nonzero on failure and prints the fixture path.
Neovim removes the temporary fixture on exit; use `NVIM_JAVA_VERIFY_DIR=/path/to/scratch/project` to keep one for diagnosis.
The check overwrites its fixture files, so use a dedicated scratch directory.
Run it without another Neovim instance editing that fixture.

Upstream references: [nvim-java](https://github.com/nvim-java/nvim-java), [JDT LS](https://github.com/eclipse-jdtls/eclipse.jdt.ls), [nvim-dap](https://github.com/mfussenegger/nvim-dap).
