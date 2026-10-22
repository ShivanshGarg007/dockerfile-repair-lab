# Dockerfile Repair Notes

## Summary

The original Dockerfile had intentional failures. The repaired Dockerfile uses a valid Node.js Alpine base image, installs dependencies reproducibly from the lockfile, places files under a consistent working directory, copies the actual runtime files, and starts the app with the existing npm script.

## Failure diagnosis and fixes

| Break family | Original problem | Repair |
|---|---|---|
| Base image | `FROM node:notfound` references a tag that does not exist | Use `node:22-alpine`, a supported Node.js image tag |
| WORKDIR / paths | Files were copied before switching into `/wrong`, making paths and runtime module resolution confusing | Set `WORKDIR /app` before any `COPY` |
| Dependencies | `npm install package-lock.json` treats the lockfile as a package argument, rather than installing the declared dependency tree | Copy `package.json` and `package-lock.json`, then run `npm ci --omit=dev` |
| Build context / copy paths | `COPY missing-folder ./missing-folder` references a path that does not exist; original `.dockerignore` also excluded `src`, which the app requires at runtime | Copy the actual `app.js`, `src`, and `public`; do not exclude `src` |
| Startup command | `npm run production` is not declared in `package.json` | Use `CMD ["npm", "start"]`, which invokes the existing `start` script |

## Build optimizations

- The base image is Alpine-based to keep the runtime image lightweight.
- Dependency manifests are copied and installed before the source code. Changes to application code can then reuse the dependency layer.
- `npm ci --omit=dev` installs the exact lockfile dependency tree without development dependencies.
- `.dockerignore` excludes host dependencies, Git metadata, logs, environment files, and local coverage output without excluding required source files.
- The container runs with `NODE_ENV=production`.

## Reproduce and validate locally

Record the actual output from your machine before submitting. I have not fabricated build logs or runtime screenshots.

```bash
# First, reproduce the original failure using the main branch version if desired.
git show main:Dockerfile

# Build the repaired image.
docker build --no-cache -t app:fixed .

# Run the app.
docker run --rm --name dockerfile-repair-lab -p 8080:8080 app:fixed

# In another terminal, verify the page and API route.
curl -i http://localhost:8080/
curl -i http://localhost:8080/api/status

# Stop the foreground container with Ctrl+C, or use:
docker stop dockerfile-repair-lab
```

Expected checks:
- The build completes successfully.
- `http://localhost:8080/` serves the success page.
- `http://localhost:8080/api/status` returns JSON with `status: "ok"`.

If Docker is available, save the real terminal output or screenshots in this repository before the final submission. Do not describe these checks as passed until you have run them.

## Suggested commit breakdown

If you want separate commits for the assignment rubric, make changes in this order and commit each stage separately:
1. `fix: use valid Node.js base image`
2. `fix: install dependencies from lockfile`
3. `fix: correct working directory and runtime file copies`
4. `fix: use existing npm start script`
5. `perf: optimize Docker layer caching and build context`

The GitHub API workflow used to prepare these files may result in one commit per file rather than the staged local commit history above. Do not claim that multiple local commits exist unless you create them with Git.

## Video walkthrough (3-5 minutes)

1. Show the original Dockerfile and explain the first failure: the invalid `node:notfound` base image. If you captured the original build output, show the exact step/error from your own run.
2. Explain the dependency install and why `npm ci` requires both manifests.
3. Explain why `WORKDIR /app` comes before copies, why the missing folder was removed, and why `src` must be copied and not ignored.
4. Explain the cache-friendly order: copy manifests, install dependencies, then copy application files.
5. Run `docker build --no-cache -t app:fixed .`, start the container, and show the browser page plus the `/api/status` endpoint.
6. Keep your face visible while recording, upload to Google Drive, set access to **Anyone with the link can view**, and test the link in a private browser window.

## Evidence checklist

- [ ] Add actual original failing-build output or a screenshot, including its exact failing step.
- [ ] Add actual clean-build output or a screenshot from `docker build --no-cache -t app:fixed .`.
- [ ] Add actual running-container and browser/API evidence.
- [ ] Record and upload the walkthrough; paste its verified public link in the PR description.
