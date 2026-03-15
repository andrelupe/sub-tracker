---
name: commit
description: Commit all current changes following conventional commit style
user-invocable: true
disable-model-invocation: true
---

Please commit all current changes in the repository.

## Rules

- Commit title: follow conventional commit style → `<type>: <summary>`
  - Types: feat, fix, chore, docs, refactor, test, style
  - Summary: <= 10 words, concise but meaningful
- Commit body: structured bullet list with specifics
  - Use `-` bullets for details
  - Bold key subsystems or files touched (e.g., **Controllers**, **Authorization**)
  - Each bullet should describe a single logical change
  - Include tests/verification steps if applicable

## Steps

1. Stage all modified and new files
   - Run `git add .`
2. Generate a commit message
   - Title: `<type>: <summary>`
   - Body: bullet-point list of detailed changes
3. Commit the changes
   - Use a HEREDOC to pass the message to `git commit`
4. Output the commit hash and the final commit message
