# Git Policy for Swift Package Development

This document outlines the Git usage policy for maintaining the integrity and management of our Swift package. As we are currently forked from the ThorVG parent repository, specific practices need to be adhered to in order to ensure smooth development and release processes.

## General Branching Strategy

- **Main Branch**: The `main` branch serves as the primary branch from which all development should branch off. It is essential for developers to use this branch for creating new features, bug fixes, or enhancements by branching off and later creating pull requests back to `main`.

## Releases

- **Release Branches**: All releases must be created from branches that specifically contain the changes for that release. Each release branch should have its own tags corresponding to the release version to ensure that we can maintain and access previous versions of the package.
- **No Tags on Main**: Given our strategy of forking and frequent rebasing from the upstream ThorVG repository, we will not create any tags or releases directly off the `main` branch. This approach ensures that `main` remains clean and continuously synchronized with the upstream without the clutter of release tags.

## Forking and Upstream Management

- **Pinned to Upstream Version**: Our repository remains pinned to a specific version of the upstream ThorVG repository. This practice requires that our `main` branch needs to be rebased against a new upstream branch whenever we decide to upgrade to a new version from the ThorVG repository.
- **Rebasing Against Upstream**: To keep up with upstream changes, `main` will be regularly rebased against the new versions of ThorVG. This approach allows us to integrate improvements and updates from the upstream while maintaining our modifications and customizations on top.
