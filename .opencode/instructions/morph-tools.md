# Morph Fast Apply Routing

Use `morph_edit` for large, scattered, or whitespace-sensitive edits.

Use `edit` for small exact replacements.

When using `morph_edit`, keep these rules in mind:

- Wrap preserved regions with `// ... existing code ...` markers.
- Include enough surrounding context to anchor the change.
- Use it for large files, multiple separate hunks, or edits where spacing matters.
- If the Morph API key is missing, set `MORPH_API_KEY`.
- If a patch goes sideways, split the edit into smaller pieces before retrying.

The routing policy belongs in OpenCode instructions, not a skill.
