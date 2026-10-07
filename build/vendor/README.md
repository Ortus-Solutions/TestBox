# Report assets

The HTML reporters (Simple, Min, Dot and Doc) inline everything they need into one page, so a report runs airgapped:
no CDN, no extra requests. This folder is where the third party pieces come from.

```
build/vendor/                  you are here: pinned dependencies and the build script (never shipped)
system/reports/assets/vendor/  generated output the reporters inline (shipped, do not edit by hand)
system/reports/assets/css/     TestBox's own styles
system/reports/assets/js/      TestBox's own behavior (Alpine component)
system/reports/assets/images/  logos from https://github.com/Ortus-Solutions/ortus-artwork
```

| Library        | Used for                                 | Output                  |
| -------------- | ---------------------------------------- | ----------------------- |
| Bootstrap      | layout, components, light and dark theme | `bootstrap.min.css`     |
| Alpine.js      | reactivity: filters, collapsing, theme   | `alpine.min.js`         |
| Bootstrap Icons| icons, as an inline SVG sprite           | `icons.svg`             |
| Prism          | syntax highlighting (CFML and BoxLang)   | `prism.min.js`          |

## Update the dependencies

From the repo root:

```bash
box run-script assets:update     # bump to the newest minor versions, install, rebuild
box run-script assets:build      # rebuild from the pinned versions in package.json
box run-script assets:check      # fail if the committed output differs from a fresh build
```

or directly in this folder: `npm ci && npm run update`.

Then:

1. Look at the diff of `system/reports/assets/vendor/VERSIONS.json`.
2. Run the tests. `ReportAssetsTest` fails if the vendored files and `package.json` disagree.
3. Open a report in light and dark mode and click around (filters, details, Ask AI).
4. Commit `package.json`, `package-lock.json` and everything under `system/reports/assets/vendor/`.

A major version bump (Bootstrap 6, Alpine 4) is a deliberate upgrade: change the version in `package.json` by hand,
rebuild and check the reports. `npm run update` only moves minor and patch versions.

CI keeps this honest: `.github/workflows/vendor-assets.yml` fails a pull request whose committed assets do not match a fresh
build, and opens an update pull request on the first of every month.

## Add an icon

Add its name from https://icons.getbootstrap.com to `icons.txt`, rebuild, then use it in a template:

```html
<svg class="tb-icon" aria-hidden="true"><use href="##i-bug"/></svg>
```

`##` is a literal `#` inside `<cfoutput>`. `ReportAssetsTest` fails when a template uses an icon that is not in the sprite.

## Add a Prism language

Add its `prism-*.min.js` file to the `prismParts` list in `build.mjs` (languages that extend another need that one first),
rebuild, and map the file extension to the language in `ReportHelper.cfc` (`variables.LANGUAGES`).

BoxLang has no official Prism grammar. `prism-boxlang.js` is ours and follows the keyword lists of the Ortus
[`brush-boxlang`](https://github.com/ortus-boxlang/brush-boxlang) SyntaxHighlighter brush: update that list first, then this file.

## Logos

`system/reports/assets/images/` holds the SVG logos from the Ortus artwork repository (see `LOGOS.md` there).
To refresh them, copy the three files again from `testbox/SVG` in that repository.
