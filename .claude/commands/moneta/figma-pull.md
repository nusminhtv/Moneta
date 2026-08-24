---
description: Pull a Figma node into the Moneta design system with a fidelity check
argument-hint: "<figma-node-url-or-id> <target-widget-name>"
---

Bring a Figma component or screen into Flutter **through the design system**, not
as a one-off widget, and prove the result matches the source.

Arguments: `$ARGUMENTS` — a Figma node URL (or bare node id) and the intended
Dart widget name.

File key for this project: `kEYXQUyhXLZITkNxAHRVlf`
(source of truth: the Moneta — Personal Finance App Figma file)

## Steps

1. **Read before writing.** Load the Figma design-to-code guidance, then call
   `get_metadata` on the node to see its structure and variants, and
   `get_design_context` for the node itself. Never implement from the screenshot
   alone — variant names carry the state model (`State=Masked`,
   `Tone=Error`, `Active=Home`).

2. **Map to tokens first.** Every colour, radius, spacing, font size and duration
   in the returned reference code must resolve to an existing entry in
   `lib/design_system/tokens/`. Produce that mapping as a short table before you
   write widget code:

   | Figma value | Token | Notes |

   If a value has no token, stop and decide deliberately: is this a missing token
   (add it, and say so) or a one-off deviation in the design (flag it to the user)?
   Do not inline the raw value — `tool/check_design_tokens.dart` will fail it.

3. **Model every variant.** A Figma component with variants becomes one widget
   with an enum or named constructors covering *all* variants, not just the one
   you were asked for. List the variants you found and confirm each is represented.

4. **Write the widget** under `lib/design_system/` — `atoms/`, `molecules/` or
   `organisms/` matching its Figma page position. Public API takes domain types
   (`Money`, not `String`) wherever the component displays domain data.

5. **Prove fidelity.** For each variant, write a widget test asserting the
   token-derived values actually reach the render tree (colour, padding, text
   style), plus a golden test where layout matters. Then run:
   ```
   bash tool/verify.sh --fast
   ```

6. **Record the mapping.** Append the node id, widget path, variants covered and
   any deviation to `docs/design-system/figma-map.md` so the next change can find
   what is already implemented instead of re-deriving it.

## Hard rules

- One Figma component → one design-system widget. Never copy the same visual into
  two feature folders.
- Deviations from the design are allowed but must be *stated*, never silent.
- If the Figma node does not exist or the file has no such variant, say so
  instead of inventing a plausible design.
