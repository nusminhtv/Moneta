# Bundled fonts

| Family | Files | Weights | Licence |
| --- | --- | --- | --- |
| Inter | `Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf` | 400, 500, 600 | SIL Open Font License 1.1 |
| Plus Jakarta Sans | `PlusJakartaSans-SemiBold.ttf`, `PlusJakartaSans-Bold.ttf` | 600, 700 | SIL Open Font License 1.1 |

Both families are the ones named in the Figma file. Static instances are bundled
rather than fetched at runtime (see decision D7 in the change's `design.md`):
runtime fetching makes first paint use a fallback face and makes golden tests
non-deterministic, and this app is local-first.

Only the weights the type scale actually uses are bundled. Adding a weight means
adding a file here and a `fontWeight` entry in `pubspec.yaml`.

Source: Google Fonts (`fonts.gstatic.com`), retrieved 2026-08-24.
