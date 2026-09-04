# Embedding screenshots and video

Keep media out of the PR branch and keep sensitive files out of uploads. Upload with `--attach` on `gh pr create` or `gh pr edit`; repeat the flag for multiple files.

Reference an image from the body with a relative path and pass the same file to `--attach`; `gh` rewrites the reference to the uploaded asset:

```markdown
![The login error state](./login.png)
```

Without a body reference, `gh` appends the attachment. Give an image alt text directly as `--attach './login.png#The login error state'`. Videos render as players and take no alt text.

If an attachment command exits nonzero, the PR may still have been created or updated with the successful uploads. Resolve the PR from stdout or the current branch, inspect it, then retry only missing files with `gh pr edit --attach`.
