# Issue tracker: GitHub

Issues and specifications for this repository live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filter comments with `jq`, and fetch labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with the applicable `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply or remove labels**: `gh issue edit <number> --add-label "..."` or `--remove-label "..."`
- **Close an issue**: `gh issue close <number> --comment "..."`

Infer the repository from `git remote -v`. `gh` does this automatically when it runs inside a clone.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set this value to `yes` if this repository treats external PRs as feature requests. `/triage` reads this flag.)_

When this value is `yes`, PRs use the same labels and states as issues:

- **Read a PR**: Use `gh pr view <number> --comments` and `gh pr diff <number>`.
- **List external PRs for triage**: Use `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments`. Keep only an `authorAssociation` value of `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, or `NONE`. Remove `OWNER`, `MEMBER`, and `COLLABORATOR`.
- **Comment, label, or close**: Use `gh pr comment`, `gh pr edit --add-label`, `gh pr edit --remove-label`, or `gh pr close`.

GitHub uses one number sequence for issues and PRs. A reference such as `#42` can identify either type. First run `gh pr view 42`. If that command fails, run `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

`/wayfinder` uses one **map** issue and its **child** issues.

- **Map**: A single issue with the `wayfinder:map` label. Its body contains Notes, Decisions-so-far, and Fog. Create it with `gh issue create --label wayfinder:map`.
- **Child ticket**: An issue that is linked to the map as a GitHub sub-issue. Use `gh api` with the sub-issues endpoint. If sub-issues are not available, add the child to a task list in the map body and add `Part of #<map>` at the top of the child body. Use a `wayfinder:<type>` label, where `<type>` is `research`, `prototype`, `grilling`, or `task`. Assign the ticket to the responsible developer after a claim.
- **Blocking**: Use native GitHub issue dependencies. Add an edge with `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`. The `<blocker-db-id>` value is the numeric database ID from `gh api repos/<owner>/<repo>/issues/<n> --jq .id`. It is not the issue number or `node_id`. GitHub reports open blockers in `issue_dependencies_summary.blocked_by`. If dependencies are not available, add `Blocked by: #<n>, #<n>` at the top of the child body. A ticket is unblocked when all blockers are closed.
- **Frontier query**: List the map's open children. Remove children that have an open blocker or an assignee. The first remaining child in map order wins.
- **Claim**: Run `gh issue edit <n> --add-assignee @me`. This command is the session's first write.
- **Resolve**: Comment with the answer, close the child, and add a context pointer with a link to the map's Decisions-so-far section.
