# Hosting images and videos for GitHub PR descriptions from a CLI-only agent

Researched: 2026-08-10.

Question: how can a CLI-only coding agent (git + `gh`, no browser) host images and
videos for GitHub PR descriptions so they render inline, stay out of the PR diff,
survive branch deletion, and work on both public and private repos?

Sources are primary where possible: GitHub's official docs, GitHub's REST API
reference, the source code of maintained tools, and live probes run on 2026-08-10
with the local `gh` token (`repo`, `workflow`, `read:org`, `gist` scopes) against the
public repo `wkentaro/skills` (repository_id 1324652119). Test comments were posted
and deleted; measured results below are from those probes unless attributed to the
caller's ground-truth measurements (throwaway repos, 2026-08-10).

## 1. The user-attachments route (`github.com/user-attachments/assets/...`)

### What the web UI calls: `/upload/policies/assets` — session-cookie only

The browser drag-and-drop flow POSTs to `https://github.com/upload/policies/assets`,
which returns an S3 presigned form plus an `asset_upload_url` to finalize; the
whole flow authenticates with the `user_session` (and `__Host-user_session_same_site`)
browser cookies and rejects PATs with HTTP 422.

- Community thread asking for an API equivalent; reverse-engineering confirmed the
  endpoint "required use of a cookie" and PATs "kept getting 422 responses"; no
  GitHub staff response: <https://github.com/orgs/community/discussions/29993>
  (see also <https://github.com/orgs/community/discussions/28219>).
- The `gh` CLI feature request <https://github.com/cli/cli/issues/13256> is open and
  labeled `blocked`/`platform` — i.e. the CLI team considers this to need a new
  official API surface first. An earlier request,
  <https://github.com/cli/cli/issues/12960>, was closed as a duplicate (of
  <https://github.com/cli/cli/issues/1895>) — itself evidence the same gap keeps
  being requested.
- Cookie-based implementations of the web flow exist and document the mechanics:
  `drogers0/gh-image` (`internal/upload/upload.go` calls
  `POST {baseURL}/upload/policies/assets`, then S3, then `PUT asset_upload_url`,
  all with session cookies): <https://github.com/drogers0/gh-image>;
  `lisonge/user-attachments` (browser-cookie based):
  <https://github.com/lisonge/user-attachments>.

There is **no documented REST or GraphQL API** for user-attachments. Everything
below in this section is undocumented behavior.

### Undocumented but token-usable: `POST https://uploads.github.com/user-attachments/assets`

An undocumented endpoint on `uploads.github.com` accepts a normal OAuth/PAT bearer
token and uploads in a single call:

```
curl -X POST \
  "https://uploads.github.com/user-attachments/assets?name=<file>&content_type=<mime>&repository_id=<id>" \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/json" \
  --data-binary @<file>
# -> 201 {"url":"https://github.com/user-attachments/assets/<uuid>"}
```

- First public write-up (2026-08): "Programmatically upload attachments to GitHub
  Issues, Pull Requests, and Comments, finally, for now" — notes it is an
  "undocumented endpoint" and "I hope it doesn't go away":
  <https://island94.org/2026/08/programmatically-upload-attachments-to-github-issues-pull-requests-comments>
- `drogers0/gh-image` uses exactly this endpoint as its primary ("bearer") route
  (`internal/upload/bearer.go`), falling back to the cookie flow when the server
  refuses; its docs state the bearer route works "only for images and video, and
  only on repositories the token can push to":
  <https://github.com/drogers0/gh-image>
- **Verified live 2026-08-10**: with the plain `repo`-scoped `gh` token, uploading a
  PNG (`content_type=image/png`) and an MP4 (`content_type=video/mp4`) against a
  public repo both returned `201` with a `github.com/user-attachments/assets/<uuid>`
  URL. No `user` scope needed.

Measured post-upload behavior (2026-08-10, asset tied to a public repo):

- Fresh, unreferenced asset: anonymous GET → **404**; GET with the uploading token
  → **200 image/png**. (Assets appear to be private-to-uploader until referenced.)
- After the URL was posted in an issue comment on the public repo: anonymous GET →
  **200 image/png**.
- After that comment was deleted: anonymous GET **still 200** — the asset outlives
  the content that referenced it (there is no delete API either; see §2).
- `body_html` for the image comment rendered as an `<img>` pointing at
  `https://private-user-images.githubusercontent.com/<user>/<id>-<uuid>.png?jwt=...`
  — a JWT-signed URL with a 5-minute expiry that GitHub mints per render.
- `body_html` for a bare `.mp4` attachment URL rendered as a native
  **`<video src="https://private-user-images.githubusercontent.com/....mp4?jwt=...">`
  player** inside a `<details>` block. This is the only route found that produces an
  inline video player.

Caller session measurements (2026-08-10, throwaway repos
`wkentaro/tmp-pr-media-test-{public,private}`), extending the above to private
repos:

- Private repo (repository_id 1329372341): PNG and MP4 uploads via the same bearer
  endpoint both returned 201 with `user-attachments` URLs.
- Embedded in a private-repo issue (`tmp-pr-media-test-private#2`), `body_html`
  rendered the image as a JWT-signed `private-user-images` `<img>` and the bare MP4
  URL as a JWT-signed `<video>` player — identical to the public repo.
- After embedding: anonymous GET of the private-repo assets → **404**; GET with the
  uploading token → **200**. Anonymous GET of the public-repo assets after
  embedding → **200** (`image/png`, `video/mp4`).
- A pre-existing attachment posted years earlier in a different private repo
  (`wkentaro/labelme-io#233`) also measured 404 anonymously / 200 with token — the
  login-gating is not specific to fresh uploads.
- Wrapping a **video** attachment URL in image syntax (`![v](...mp4-attachment...)`)
  renders as an `<img>` whose `src` is the `.mp4` — a broken image, not a player.
  Only the bare URL on its own line produces the `<video>` player.
- **Browser-verified (owner session, Brave, 2026-08-10)** on the private repo's
  render-test issue: the `github.com/<owner>/<repo>/raw/<sha>/` image form and the
  published-release `releases/download/` form both **render inline** for a
  logged-in viewer (github.com receives session cookies and redirects with an
  access token), while the `raw.githubusercontent.com` form shows a broken image
  (that domain receives no credentials). So "raw URLs are dead on private repos"
  holds only for `raw.githubusercontent.com`; the github.com-domain forms work for
  viewers with repo access, though they still 404 for anonymous and token-less
  fetchers.

### The VS Code GitHub PR extension's route: `POST /mobile/upload/policy`

`microsoft/vscode-pull-request-github` (which supports pasting images into PR
descriptions/comments since v0.144.0, tracked in
<https://github.com/microsoft/vscode-pull-request-github/issues/2760> and
<https://github.com/microsoft/vscode-pull-request-github/issues/8733>) uses a
different undocumented endpoint, the **mobile upload policy API** on
`api.github.com`. From `src/github/githubRepository.ts` (`uploadFileBytes`, on
`main` as of 2026-08-10):

1. `POST /mobile/upload/policy` via octokit with `{name, size, content_type, repository_id}`
   → returns `{upload_url, form, asset: {href}, asset_upload_url}`;
2. multipart POST of the bytes to `upload_url` (S3) with the returned `form` fields;
3. `PUT {asset_upload_url}` to confirm; `asset.href` is the final
   `user-attachments` URL. Client-side cap: 25 MB.

Source: <https://github.com/microsoft/vscode-pull-request-github/blob/main/src/github/githubRepository.ts>

**Verified live 2026-08-10**: `gh api -X POST /mobile/upload/policy ...` with the
`repo`-scoped token returns 404 plus the hint *"This API operation needs the "user"
scope"* — so the endpoint exists and takes token auth, but needs the `user` scope
(the VS Code OAuth app token has it; a default `gh` login does not). The
`uploads.github.com` endpoint above is therefore the more practical one for `gh`.

### Stability and access-control guarantees

- GitHub documents attachment URLs only as "anonymized URLs" served from
  `<subdomain>.githubusercontent.com`, and warns: "Anyone who receives your
  anonymized URL, directly or indirectly, may view your image or video":
  <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-anonymized-urls>
- Since May 2023 ("More secure private attachments — GA"), **new** attachments
  associated with private repositories "can only be viewed after logging in";
  rendered pages use `private-user-images.githubusercontent.com` URLs signed with a
  JWT that expires in ~5 minutes. Pre-existing private attachments remain
  public-by-unguessable-URL. GitHub staff: "The old behavior was a bug, but it was a
  load-bearing bug": <https://github.com/orgs/community/discussions/54551>
- Official docs on the privacy model: "For public repositories, uploaded files can
  be accessed without authentication. In the case of private and internal
  repositories, only people with access to the repository can view the uploaded
  files": <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files>
- No documented guarantee covers the *upload* endpoints themselves: both
  `uploads.github.com/user-attachments/assets` and `/mobile/upload/policy` are
  unlisted in the REST reference and could change without notice
  (<https://github.com/orgs/community/discussions/29993>,
  <https://github.com/cli/cli/issues/13256>).

## 2. Official docs: file attachments in issues/PRs

Source: <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files>

- **Formats (all contexts)**: PNG, GIF, JPEG, SVG; video MP4, MOV, WebM (H.264
  recommended for cross-browser playback); plus PDFs, Office docs, text/code files,
  ZIP/GZ/TGZ, etc.
- **Size limits**: images and GIFs 10 MB; videos 10 MB on free plans, 100 MB on
  paid plans; all other files 25 MB.
- **URLs**: "When you attach a file, it is uploaded immediately to GitHub and the
  text field is updated to show the anonymized URL for the file."
- **Permanence**: the docs make no statement about attachment lifetime and provide
  no way to delete an attachment; the API cannot download private attachments
  either (community-verified, e.g.
  <https://codenote.net/en/posts/github-issue-attachments-download-api-unsupported/>).
  Measured 2026-08-10: an attachment stayed live after the referencing comment was
  deleted.
- **Privacy**: public-repo attachments are accessible without authentication;
  private/internal-repo attachments require repo access (post-May-2023 uploads).

## 3. How screenshot / visual-regression bots host media

The commercial visual-testing ecosystem does **not** use GitHub to host media; each
service runs its own upload endpoint backed by its own storage/CDN, and PR
integration is mostly status checks / links out rather than inline images:

- **Percy (BrowserStack)**: SDKs upload DOM snapshots to Percy's API; rendering and
  screenshots live in Percy's cloud, viewed on the percy.io build page; PRs get a
  status check linking there:
  <https://www.browserstack.com/docs/percy/integrate/percy-sdk-workflow>
- **Chromatic**: snapshots are captured in and stored on Chromatic's cloud
  (<https://www.chromatic.com/docs/snapshots/>), with builds "published
  automatically to a secure CDN": <https://www.chromatic.com/features/publish>
- **Argos**: screenshots are uploaded from CI to Argos; the (source-available)
  production stack runs on AWS with S3 storage; self-hosting is not officially
  supported: <https://argos-ci.com/docs>
- **Lost Pixel**: OSS mode keeps baseline PNGs *committed in your repo* (diffs live
  in CI artifacts); Platform mode stores them in Lost Pixel's cloud:
  <https://docs.lost-pixel.com/user-docs/setup/project-configuration/baseline-images>,
  <https://docs.lost-pixel.com/user-docs/readme-1>
- **GitHub Actions that inline screenshots into PR comments** fall back to exactly
  the routes an infrastructure-less agent would: `saadmk11/comment-webpage-screenshot`
  offers `upload_to: github_branch` (commit screenshots to a bot-created branch in
  the same repo and reference them) or `upload_to: imgur` (public, rate-limited):
  <https://github.com/saadmk11/comment-webpage-screenshot>; similarly
  <https://github.com/opengisch/comment-pr-with-images> (branch-based) and
  <https://github.com/DryCreations/screenshot-workflow> (Imgur).
- **uploads.sh** is a newer third-party host aimed specifically at agents attaching
  media to PRs (own storage, stable keys, workspace-token auth); its docs state
  files are "public to anyone with the URL, even media attached to private repos",
  and that GitHub "only plays videos it hosts itself":
  <https://uploads.sh/github-screenshots>

Implication: the ecosystem pattern is "own upload endpoint + own image store".
Anyone who wants zero external infrastructure is pushed back onto GitHub-native
hosting: user-attachments (§1) or in-repo branches / releases (§4).

## 4. GitHub-native hosting routes in private repos (community-verified + measured)

Ground truth measured 2026-08-10 on throwaway repos (caller's measurements):

- Public repo, SHA-pinned `raw.githubusercontent.com` URL: serves `image/png`
  anonymously and renders as a **direct `<img>`** in `body_html`.
- Private repo raw URL: anonymous → **404**; **200 only with a token header**.
- Draft-release assets: **404 anonymously even on public repos**.
- Published release assets: `application/octet-stream` on public repos; **404
  anonymously on private repos**.
- A raw `.mp4` link renders as a **plain link, not a player**.

Corroborating primary sources:

- **raw.githubusercontent.com on private repos** requires an `Authorization` header;
  the `?token=` query parameter is not a supported PAT mechanism
  (<https://github.com/orgs/community/discussions/147809>). GitHub's Camo image
  proxy fetches images **anonymously**, so it cannot fetch private raw URLs — docs:
  "if an image is being served from ... a server that requires authentication, it
  can't be viewed by GitHub":
  <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-anonymized-urls>.
  Consequence, confirmed in <https://github.com/cli/cli/issues/13256>: private-repo
  raw URLs embedded in PR/issue markdown show as **broken images even for logged-in
  viewers with repo access** — GitHub's web UI does *not* mint viewer-scoped tokens
  for raw URLs inside issue/PR bodies. Measured in §1's session probes: `body_html`
  embeds raw URLs verbatim with no JWT rewriting, while user-attachment URLs in the
  same bodies are rewritten to JWT-signed `private-user-images` URLs.
- **Orphan-branch assets** are just raw URLs, so they inherit all of the above:
  fine inline on public repos, broken inline on private repos. Branch-deletion
  caveat: a SHA-pinned raw URL keeps working only while the commit stays reachable
  from **some ref the repo keeps** — a branch, a tag, or `refs/pull/<n>/head` —
  so the orphan branch must be **kept**, not deleted, for durability (a deleted
  orphan branch leaves its commit with no ref at all). Probed 2026-08-10:
  `refs/pull/<n>/head` does keep raw URLs alive — `astral-sh/uv#21033`
  (squash-merged: single-parent merge commit, head `d73f33d3` unreachable from
  `main`, branch deleted) and the 2024-vintage squash-merged `astral-sh/uv#9000`
  both still serve **200 with correct per-commit content** from
  `raw.githubusercontent.com`, so a PR head SHA keeps serving even after a squash
  merge deletes the branch. (An earlier probe in this round reported 404 for
  `cli/cli#14102`'s head; that used a mistyped SHA, and that PR was a two-parent
  merge anyway — superseded by the two probes above.)
- **Release assets**: upload via `POST https://uploads.github.com/repos/{owner}/{repo}/releases/{id}/assets`
  with raw binary body; download via `browser_download_url` or the API asset URL
  with `Accept: application/octet-stream` (200 or 302):
  <https://docs.github.com/en/rest/releases/assets>. Draft releases are restricted:
  "Information about published releases are available to everyone. Only users with
  push access will receive listings for draft releases":
  <https://docs.github.com/en/rest/releases/releases>. Because private-repo assets
  need token auth and even public ones serve `application/octet-stream`, release
  assets are unreliable as inline `<img>` sources and useless in private-repo
  markdown (Camo again cannot authenticate).
- GitHub's web UI does not make any of these token-gated URLs render inline for
  logged-in private-repo viewers; the only URLs it rewrites into viewer-scoped
  JWT-signed `private-user-images.githubusercontent.com` URLs are **user-attachment
  URLs** (measured in §1) — which is why the user-attachments route is the only
  fully inline-rendering option for private repos.

## Implications for the skill

The operational ranking and steps derived from this research live in
`skills/in-progress/sending-pull-request/MEDIA.md`; this file is the evidence
trail. External hosts (Imgur, uploads.sh, S3, visual-testing SaaS) add
infrastructure, and anything Camo can fetch anonymously is public — a bad default
for private-repo media.
