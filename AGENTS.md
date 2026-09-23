# Scene Access Platform agent instructions

## Scope and priorities

This repository is the only integration workspace for Scene Access Platform.
These instructions apply to the platform root and both Git submodules.

Work in this order:

1. Preserve ignored local data, secrets, licensed media, and deployment state.
2. Keep the platform and component Git histories correct and reviewable.
3. Validate changes locally at the narrowest useful level, then at platform
   level when a component pointer or cross-component contract changes.
4. Publish only the intended source commits, followed by the tested platform
   submodule pointers.
5. Treat production deployment as a separate, explicitly approved operation.

Do not create another clone or copied source tree. The canonical local paths
are this repository, `gateway/`, and `wolf3d/`.

## Repository ownership

- `gateway/` owns the portal, Scene Management, backend, Authentik contracts,
  security monitoring, artwork, audio integration, and portable containers.
- `wolf3d/` owns the GPL Wolf3D/Spear extension, its runtime source, local game
  data import, and extension tests.
- The platform root owns compatible component commit pairing, combined Compose,
  integration checks, synchronization policy, and operator documentation.

Make a source change in the repository that owns it. A platform commit may
change orchestration files and submodule pointers; it must not contain copied
component source.

## Agent routing

Use one coordinating agent to own Git state, final integration validation, and
the publish sequence. If the user explicitly requests delegation, divide work
by repository or by a read-only specialty:

- gateway implementation: `gateway/` only;
- Wolf extension implementation: `wolf3d/` only;
- security review: read-only review of authentication, event handling, alert
  delivery, secret boundaries, and abuse cases;
- release review: read-only review of diffs, licensing, public documentation,
  CI, submodule pointers, and ignored-data boundaries.

Do not let multiple agents edit the same files or run Git history-changing
commands concurrently. Subagents do not commit, rebase, push, change submodule
pointers, start deployment, or clean worktrees unless the coordinating agent
has assigned that exact action. The coordinator rechecks all three worktrees
after delegated work.

## Mandatory start-of-work preflight

Before editing, run:

```sh
./scripts/check-workspace.sh
git status --short --branch
git -C gateway status --short --branch
git -C wolf3d status --short --branch
git submodule status
```

Treat all pre-existing changes and untracked files as user-owned. Do not
discard, overwrite, stage, or reformat unrelated work. If an intended edit
overlaps an existing change, stop and ask before proceeding.

Check the active branch and remote in the repository being changed. A detached
submodule HEAD is normal after checkout but is not a development branch: create
or switch to an intentional component branch before committing.

## Protected local data

Never read, print, copy, stage, commit, upload, package into public images, or
delete the contents of protected local data unless the user requests a narrowly
scoped local verification that requires it. Protected data includes:

- `gateway/.env` and every `gateway/.env.*` except `.env.example`;
- `gateway/.local/`, including source and installed audio;
- root `.env`, `.local/`, proxy overrides, certificates, and deployment files;
- commercial files under `wolf3d/runtime/` (`*.WL1`, `*.WL3`, `*.WL6`,
  `*.SOD`, and `*.SD1` through `*.SD3`);
- credentials, keys, databases, exports, runtime state, and host-specific
  configuration anywhere in the workspace.

Tracked engine files under `wolf3d/runtime/` are source code; the commercial
game-data extensions listed above are not.

Never use `git add -f`, `git clean`, destructive reset/checkout/restore, or a
broad recursive delete in this workspace. Do not use stash as a substitute for
understanding user-owned changes. Stage explicit paths and inspect the staged
diff plus `git status --ignored` before every commit.

Do not expose secret values in logs, tests, commit messages, patches, or chat.
Validation should check presence, permissions, names, hashes, or counts without
printing contents.

## Local-first workflow

For work authored locally:

1. Run the preflight and identify the owning repository.
2. Update that repository's `main` with a clean fast-forward when needed, then
   create an intentional feature branch inside the component.
3. Make focused changes and run the component's tests.
4. For gateway or cross-component behavior, run `./scripts/test.sh`; run
   `./scripts/build.sh` when containers or build inputs changed. A build does
   not authorize deployment.
5. Review unstaged and staged diffs. Commit only in the owning component.
6. When publishing was requested, use that component's
   `scripts/sync-branch.sh`; it fetches, rebases on `origin/main`, retests, and
   pushes the current branch.
7. After the component commit is final and available to collaborators, update
   the platform pointer, rerun platform tests, and commit the pointer at root.
8. Push the platform commit only after a platform remote exists and publishing
   the integration state was requested.

For a coordinated gateway/Wolf change, use matching intentional branches,
test the exact pair from the platform, publish both component commits, then
publish one platform commit recording the tested pair. Never publish a
platform pointer to a component commit that collaborators cannot fetch.

## Remote-first workflow

For code authored remotely:

1. Run the preflight. Do not pull over local component changes.
2. Fetch the relevant component and inspect the incoming commits/diff.
3. For merged `main` updates, run `./scripts/update-components.sh`. It requires
   clean worktrees, uses fast-forward-only pulls, and runs platform integration
   tests.
4. For an unmerged remote branch, create a local tracking branch inside the
   owning component. Do not move `main` or rewrite the remote branch merely to
   test it.
5. Run component tests, then platform tests/builds appropriate to the change.
6. Make fixes on an intentional component branch, commit and publish them only
   when requested, and repeat validation.
7. Commit the platform pointers only after the final component commits and
   exact pair have passed integration tests.

Pulls must be fast-forward-only. Rebases belong on intentional feature branches
via the component sync scripts, never on shared or user-owned work without
explicit approval. Do not force-push.

## Validation matrix

- documentation or root policy only: `./scripts/check-workspace.sh` plus
  relevant link/shell checks;
- gateway-only source: `gateway/scripts/test.sh`;
- Wolf-only source: `wolf3d/scripts/test.sh`;
- submodule pointer, Compose, shared contract, or cross-component behavior:
  `./scripts/test.sh`;
- Dockerfiles, dependencies, assets, Compose build inputs, or release images:
  `./scripts/build.sh` after tests;
- runtime route behavior: the relevant smoke test, using only local protected
  inputs and without printing them.

Report exactly what ran and what did not. Do not claim deployment validation
from a local build or CI result.

## Commits and synchronization

Before committing in any repository:

```sh
git status --short --branch
git diff --check
git diff --cached --check
git diff --cached
```

Use explicit pathspecs for staging. Keep generated files, private overrides,
audio, commercial game data, and secrets out of commits. A component commit and
a platform pointer commit are separate commits in separate repositories.

Normal publish order is gateway and/or Wolf component first, platform last.
Normal consume order is fetch/review components, validate the pair, platform
pointer commit last. Never treat a changed submodule pointer alone as proof that
the corresponding component commit was pushed or tested.

The platform currently has no remote. Do not invent one. Add it only when the
user supplies or confirms its URL.

## Deployment boundary

No test, build, sync, push, or CI success authorizes a TrueNAS or production
deployment. Before any deployment, require a reviewed procedure that identifies
the exact target, image versions/digests, configuration mounts, backup and
rollback steps, health checks, and secret handling. Then obtain explicit user
approval for that deployment. Never infer approval from a request to build,
test, commit, push, synchronize, or prepare a release.

Environment-specific settings remain in ignored local mounts or the target's
secret/configuration mechanism. They must not be embedded in public images.
