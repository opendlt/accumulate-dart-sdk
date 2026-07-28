# opendlt-dart-v2v3-sdk — repository guide for agents

The Dart SDK for the Accumulate blockchain. Published as `opendlt_accumulate` (v2.3.2).

> **The project root is `unified/`, not the repository root.** Run every command below from there unless stated otherwise.

> Building **on** Accumulate rather than **on this SDK**? You want `llms.txt` (quickstart + rules) and `llms-full.txt` (full API). This file is about working on the SDK itself.

## Setup

Toolchain: **Dart SDK >=3.3.0 <4.0.0**

```bash
cd unified
dart pub get
```

## Build

```bash
dart pub get   # no separate build step
```

## Test

| Command | Covers | Needs network |
|---|---|:--:|
| `dart test` | full suite | no |
| `dart test test/integration` | integration | **yes** |

Network-dependent suites talk to a live testnet. If they fail while the unit suite passes, suspect the network before suspecting your change.

## Lint & format

```bash
dart analyze
dart format --output=none --set-exit-if-changed .
```

## Layout

```
unified/lib/            the package (this is the real project root)
unified/test/           test suite
unified/example/v3/     runnable examples
unified/bin/            CLI entry point
```

## Gotchas

- The repo root is not the package root; `unified/` holds `pubspec.yaml`.
- pub.dev analysis currently reports `has:error` and scores 40/160. Run `dart analyze` and `dart doc` before publishing — analyzer errors degrade code intelligence for every consumer, human or agent.
- Errors are typed via `AccError` / `JsonRpcErrorMapper`, wired into `Transport.call`/`batch`. Catch `on AccError`, not a bare exception.

## Permitted commands

Safe to run unattended: build, test, lint, format, and any read-only query against a **testnet**.

Require a human first:

- publishing or releasing (registry writes are irreversible)
- anything targeting **mainnet**
- rewriting git history, force-pushing, or changing CI credentials
- changing transaction marshaling or signing bytes — consensus-visible

## Before you commit

```bash
dart analyze && dart test
```
