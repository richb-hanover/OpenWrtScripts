# CLAUDE.md - OpenWrtScripts

## Project Overview

A collection of POSIX shell scripts for reporting, configuring, and measuring latency on [OpenWrt](https://openwrt.org) home routers. The scripts are designed to run directly on OpenWrt devices (typically installed to `/usr/lib/OpenWrtScripts`) or from a local machine via SSH. Licensed under GPLv2.

Repository: `github.com/richb-hanover/OpenWrtScripts`

## Repository Structure

```
OpenWrtScripts/
├── betterspeedtest.sh       # Speed test with latency measurement under load
├── netperfrunner.sh         # Concurrent up/down netperf stress test with latency
├── idlelatency.sh           # Idle line latency measurement (DEPRECATED - use betterspeedtest.sh --idle)
├── getstats.sh              # Collects diagnostic info from an OpenWrt router
├── config-openwrt.sh        # Template script to configure OpenWrt after firmware flash
├── config-spare-router.sh   # Configures a "spare router" to known defaults
├── print-router-label.sh    # Prints a label with router credentials for physical attachment
├── opkgscript.sh            # Save/restore installed packages across sysupgrades (DEPRECATED)
├── tunnelbroker.sh          # Sets up IPv6 6-in-4 tunnel via Hurricane Electric
├── lib/
│   └── summarize_pings.sh   # Shared library: ping result summarization function
├── tests/
│   ├── test_summary.sh      # Test harness for summarize_pings()
│   └── pingsamples.txt      # Sample ping data for tests
├── TestScripts/
│   ├── snmp.sh              # Example: configure SNMP on OpenWrt
│   └── sqm.sh               # Example: configure SQM (Smart Queue Management)
├── sample_output/
│   └── openwrtstats.txt     # Sample output from getstats.sh
├── Why a Spare Router?.md   # Documentation for the spare router concept
├── README.md                # Main project documentation
└── LICENSE                  # GPLv2
```

## Shell Script Conventions

### Language and Compatibility

- All scripts use **POSIX sh** (`#!/bin/sh`), not bash. This is required because OpenWrt uses BusyBox ash, which does not support bashisms.
- Do not use bash-specific features: no arrays, no `[[ ]]`, no `$(( ))` arithmetic beyond POSIX, no process substitution `<()`, no `{a,b}` brace expansion.
- Use `[ $# -gt 0 ]` style tests, `$(command)` or backtick substitution, and `case`/`esac` for option parsing.

### Script Header Pattern

Each script follows this pattern:
1. Shebang line: `#!/bin/sh` or `#! /bin/sh`
2. Description comment block explaining purpose
3. Usage line showing invocation syntax
4. Options documentation in comments
5. Copyright notice with GPLv2 reference

### Option Parsing

Scripts use a `while [ $# -gt 0 ]` loop with `case`/`esac` for argument parsing. Common options across network testing scripts:
- `-H | --host` - netperf server hostname
- `-4 | -6` - IPv4 or IPv6 selection
- `-t | --time` - test duration in seconds
- `-p | --ping` - host to ping for latency
- `-n | --number` - number of simultaneous sessions
- `-Z` - passphrase for netperf.bufferbloat.net

### Shared Code

The `summarize_pings()` function is the core latency analysis routine. It exists in three places:
- `lib/summarize_pings.sh` - canonical shared library version
- `betterspeedtest.sh` - inline copy
- `netperfrunner.sh` - inline copy
- `idlelatency.sh` - older inline variant

When modifying `summarize_pings()`, update all copies. The `lib/` version is sourced by tests via `. "../lib/summarize_pings.sh"`.

The `print_router_label()` function is duplicated between `print-router-label.sh` and `config-spare-router.sh`. Changes must be synchronized manually (noted as a maintenance hassle in the code).

### Temp Files

Scripts use `mktemp` with descriptive patterns:
```sh
PINGFILE=$(mktemp /tmp/measurepings.XXXXXX) || exit 1
```
Always clean up temp files in cleanup/trap handlers.

### Process Management

Network testing scripts manage background processes (pings, dots progress indicator, netperf sessions) and use `trap` for signal handling:
```sh
trap catch_interrupt HUP INT TERM
```

## Testing

### Running Tests

The only test is for the `summarize_pings()` function:

```sh
cd tests
sh test_summary.sh <number_of_lines>
```

This sources `lib/summarize_pings.sh`, feeds a specified number of lines from `pingsamples.txt` through the function, and displays results. The test is manual - verify output visually.

### No Build System

There is no build step, no linter configuration, no CI/CD pipeline, and no package manager. Scripts are plain shell files run directly with `sh`.

## Key Dependencies

- **netperf**: Required by `betterspeedtest.sh` and `netperfrunner.sh` for bandwidth testing. Scripts check for its presence and exit with an error if missing.
- **OpenWrt UCI**: Configuration scripts (`config-*.sh`, `print-router-label.sh`) use the `uci` command-line interface for reading/writing OpenWrt configuration. These scripts only work on OpenWrt devices.
- **Standard POSIX utilities**: `ping`, `awk`, `sed`, `grep`, `sort`, `mktemp`, `pgrep`, `wc`, `date`

## Development Guidelines

- Keep scripts self-contained where possible. The project favors copy-pasting functions over complex sourcing/dependency chains.
- Configuration scripts (`config-openwrt.sh`) are templates - most sections are commented out by design. Users copy and uncomment what they need.
- Default branch is `master`.
- Use tabs for indentation in functions that interact with UCI (matching OpenWrt convention). The network testing scripts use a mix of spaces and tabs - follow the existing style of the file being edited.
- When adding new scripts, include a usage comment block, copyright header, and add documentation to `README.md`.
