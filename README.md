# Wisdom scripts (shared tooling)

Automation used across Wisdom repos: GitHub bootstrap, **shared Git hooks** (`git-hooks/`), and installers.

## Consuming this repo from app, cube, contracts, etc.

Use a **git submodule** so each consumer pins a commit of scripts and can update deliberately.

1. From the **consumer** repository root (e.g. `cube/`):

   ```bash
   git submodule add https://github.com/Wisdom-PA/scripts.git wisdom-scripts
   git submodule update --init
   ```

2. Point Git at the hooks (pick one):

   - **PowerShell** (from consumer root): run the installer from the submodule:

     ```powershell
     .\wisdom-scripts\install-main-branch-hooks.ps1 -Mode Submodule -OnlyCurrentRepo
     ```

   - **Manual:** `git config core.hooksPath wisdom-scripts/git-hooks`

3. Commit `.gitmodules` and the `wisdom-scripts` submodule pointer on a feature branch; merge via PR.

After `git clone` of a consumer, run `git submodule update --init --recursive` (or clone with `--recurse-submodules`), then set `core.hooksPath` again if the clone did not preserve local config (hooksPath is local git config, not committed—document “run installer after clone” in the consumer README or a `CONTRIBUTING.md`).

## Local Wisdom workspace (all repos as siblings)

If `app/`, `cube/`, `scripts/`, … sit under one parent folder with **no** submodule, use **Workspace** mode (default):

```powershell
.\scripts\install-main-branch-hooks.ps1
```

```bash
bash scripts/install-main-branch-hooks.sh
```

## Submodule mode from the Wisdom parent folder

If every sibling repo already contains `wisdom-scripts/`:

```powershell
.\scripts\install-main-branch-hooks.ps1 -Mode Submodule
```

```bash
WISDOM_HOOKS_MODE=submodule bash scripts/install-main-branch-hooks.sh
```

## CI (GitHub Actions): scripts sync, lint, and test on every PR

Consumer repos (app, cube, contracts, backend, listener) use **`.github/workflows/ci.yml`**. On each **pull request** and **push to `main`** it runs three jobs (all must pass for a green build):

1. **Wisdom scripts** — checks out submodules (if any), then **`Wisdom-PA/scripts/.github/actions/wisdom-scripts-sync@main`** so the job uses **latest `main` of the scripts repo** (the committed submodule pointer is not used for that step).
2. **Lint** — ESLint (app), Checkstyle (Java), Redocly lint (contracts), markdownlint (listener), etc.
3. **Test** — Jest (app), `mvn verify` / `mvn test` (Java), OpenAPI bundle smoke (contracts), Node tests (listener).

**Branch protection:** In each GitHub repo, under **Settings → Branches → Branch protection rule for `main`**, enable **Require status checks to pass before merging** and select **`Lint`**, **`Test`**, and **`Wisdom scripts`** (workflow name **CI**). That blocks merging when any job fails.

**Deploy order**

1. Create and push the **`scripts`** repository to GitHub first (so `main` contains `git-hooks/` and `.github/actions/wisdom-scripts-sync/action.yml`).
2. Add the **`wisdom-scripts`** submodule to each consumer (`bootstrap-wisdom-submodules.ps1` / `.sh`), commit on a feature branch, merge via PR.
3. Enable workflows on each consumer repo. If the composite action is not reachable yet, copy `templates/github/wisdom-scripts-pr-standalone.yml` to `.github/workflows/ci.yml` and merge its steps into the **Wisdom scripts** job (or run it as a separate workflow file).

To point at a fork, change the URL in `ci.yml` or set a repository variable `WISDOM_SCRIPTS_REPO` and adjust the standalone template / action `inputs.scripts-repo` (composite supports `with: scripts-repo: ...`).

## Push checklist (local workspace → GitHub)

1. **`gh auth login`** (or set `GH_TOKEN`) so `gh` can create/push repos.
2. **Create and push `scripts` first** on branch `chore/initial-scripts-repo` (or merge it to `main` on GitHub so `@main` resolves for composite actions).
3. **Push each consumer’s** `chore/wisdom-scripts-integration` branch and open PRs to `main` (do not push these commits directly to `main`).
4. If you added submodules with a **local** URL (`../scripts` / `file:`), run **`set-wisdom-submodule-remote.ps1`** before pushing consumers so `.gitmodules` uses `https://github.com/Wisdom-PA/scripts.git` (or pass your fork URL).

## Bootstrap submodules (all consumers from Wisdom root)

After **`scripts`** exists on GitHub:

```powershell
.\scripts\bootstrap-wisdom-submodules.ps1
# or another remote:
.\scripts\bootstrap-wisdom-submodules.ps1 -ScriptsRepoUrl https://github.com/your-org/scripts.git
```

```bash
bash scripts/bootstrap-wisdom-submodules.sh https://github.com/Wisdom-PA/scripts.git
```

Then commit `.gitmodules` and the submodule reference **on a feature branch** in each consumer (not on `main`).

## npm / Maven

Hooks are shell scripts; submodule (or a shallow copy in CI) is the portable approach. Optional: publish a small npm package later that only wraps `git config` and documents the submodule path—only useful where Node is already required.
