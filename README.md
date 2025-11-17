# DraftMode Clone

This repository is a ready-to-clone starter for spinning up a clean Flutter project. Pull it down, rename the package, and you have a fully configured workspace with up-to-date Flutter constraints, localization scaffolding, and a helper script for refreshing dependencies.

As we keep building, this README will expand into a living reference that captures everything you need to develop productively with Flutter—from environment setup tips and code style guidance to build, test, and release workflows. Check back often as we document more of the recommended practices.

## Github
### Protect your `main` branch
- Got to you repo on [Github.com](https://github.com)
- Click ⚙️ Settings.
- In the left sidebar, click Branches.
- "Add classic branch protection rule"
- Set **Branch name patter** to `main`
- [x] Require a pull request before merging
- [x] Require status checks to pass before merging
- Click **Save**
### .git/hook/pre-commit
```
#!/bin/sh

printf '\nRunning dart format --output=write .\n'
if ! dart format --output=write .; then
  echo 'dart format failed; aborting commit.'
  exit 1
fi
```
```bash
chmod +x .git/hook/pre-commit
```

## Workflows
Recommended workflow files
- [.github/workflows/ci.yml](https://github.com/draftm0de/github.workflows/blob/main/.github/workflows/flutter-ci.md)
- [.github/workflows/release.yml](https://github.com/draftm0de/github.workflows/blob/main/.github/workflows/flutter-release.md)
