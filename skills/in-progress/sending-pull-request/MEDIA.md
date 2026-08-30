# Embedding screenshots and video

GitHub routes only; GitLab equivalents are unverified. Media proves a change without polluting it: the binary never enters the PR branch, so the diff stays reviewable and the repo history stays clean. The primary route and the dead routes were probed empirically on 2026-08-10 against both a public and a private repo; the raw-URL form the orphan-branch fallback produces was probed on a public repo. Routes that failed verification are listed at the end so they don't get re-invented.

The visibility gate is exactly `gh repo view --json isPrivate`. Run it before choosing any repository-backed URL; `raw.githubusercontent.com` images do not render for private-repository viewers.

## Primary route — user-attachments upload

Works for images and video, on public and private repos, end to end from the CLI. It POSTs to an endpoint that mints the same `user-attachments` URLs the web UI's drag-and-drop produces (the browser itself calls a different, cookie-authenticated endpoint that rejects tokens). The endpoint is undocumented and GitHub may change it without notice — say so when recommending it, and on any failed upload (`curl -f` exits non-zero) switch to a fallback below.

```bash
REPO_ID=$(gh api 'repos/{owner}/{repo}' --jq .id)
curl -sSf -X POST "https://uploads.github.com/user-attachments/assets?name=<basename>&content_type=<mime>&repository_id=$REPO_ID" \
  -H "Authorization: Bearer $(gh auth token)" -H "Accept: application/json" --data-binary @<path>
```

The token needs push access to the repo named by `repository_id` (plain `repo` scope suffices). The response is `{"url": "https://github.com/user-attachments/assets/<uuid>"}`. Embed it by kind:

- **Image**: `![alt](url)`.
- **Video**: `.mp4` with `content_type=video/mp4` (verified; GitHub's docs also accept `.mov` and `.webm`). Paste the URL as its own bare line — GitHub renders an inline player. Image syntax around a video URL does not.

Properties (measured):

- Once the URL is referenced in a body or comment, the asset inherits the repo's access control: anonymous fetch returns 200 for a public-repo asset and 404 for a private-repo one, while viewers with repo access get a signed URL when the page renders. A fresh, never-referenced asset returns 404 anonymously even on a public repo, so verify an upload with the token (`curl -H "Authorization: Bearer $(gh auth token)"`), never anonymously.
- The URL references no branch or commit, so it survives merge and branch deletion; it survives deletion of the comment that referenced it too.
- There is no deletion API — treat every upload as permanent, and keep anything sensitive out.

Limits from GitHub's docs: images up to 10MB; video up to 10MB on free plans and 100MB on paid.

## Fallback — images only: orphan `assets` branch

Start from a clean tree and copy the image outside the checkout before any branch change — `git rm -rf .` wipes the tracked files, so uncommitted work or an unstaged image inside the checkout would be lost — and return to the original branch by name, since `git checkout -` does not work after `--orphan`. Use a distinct `mktemp` staging directory even when the source is already in `/tmp`; the branch surgery must consume the staged copy rather than the source path:

```bash
BR=$(git branch --show-current) && ASSET_STAGE=$(mktemp -d) &&
cp <image> "$ASSET_STAGE/<name>" &&
git checkout --orphan assets && git rm -rf . &&
cp "$ASSET_STAGE/<name>" . && git add <name> && git commit -m "assets" &&
git push origin assets && git checkout "$BR" && rm -r "$ASSET_STAGE"
```

When the `assets` branch already exists, `git checkout assets` replaces the `--orphan` and `git rm -rf .` steps. Capture the full SHA (`git rev-parse assets`) and embed with a full-commit-SHA-pinned raw URL, choosing the form by repo visibility:

```
Public:  https://raw.githubusercontent.com/<owner>/<repo>/<full-assets-sha>/<name>
Private: https://github.com/<owner>/<repo>/raw/<full-assets-sha>/<name>
```

On a private repo only the `github.com/.../raw/...` form renders: the viewer's browser sends session cookies to github.com, which redirects with an access token, so logged-in viewers with repo access see the image (browser-verified); the `raw.githubusercontent.com` form gets no credentials and shows a broken image (below). Keep the `assets` branch permanently — the URL works only while the commit is reachable from some ref the repo keeps, and deleting the orphan branch leaves its commit with none. The orphan branch shares no history with `main`, so the binaries never appear in any PR diff. For an asset that is legitimately committed as part of the change itself, the same full-SHA-pinned form applies and the full PR head SHA is fine to pin: `refs/pull/<n>/head` keeps it served even after a squash merge deletes the branch (probed).

## Fallback — hand the upload to the human

Drag-and-drop into the PR description box on github.com produces the same kind of user-attachments URL with no agent-held credentials involved. When the primary route fails, ask the human to upload and paste back the URL.

## Dead routes — verified broken, do not use

- **Draft release assets**: 404 anonymously even on public repos.
- **Raw-URL video**: renders as a plain link on every visibility — never a player.
- **`raw.githubusercontent.com` URLs on a private repo**: broken image for every browser viewer (the domain receives no session credentials); only token-bearing requests succeed. Use the `github.com/.../raw/...` form there instead (above).
- **Published release assets**: render inline for browser viewers on both visibilities (browser-verified) but 404 for anonymous fetchers on private repos, serve `application/octet-stream`, and drag a release/tag along for every asset — the routes above beat them everywhere.
