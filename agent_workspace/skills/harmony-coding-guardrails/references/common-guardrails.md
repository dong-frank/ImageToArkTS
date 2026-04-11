# Common Guardrails

## 1. Entry Page And Registered Pages Must Match

Problem pattern:

- `EntryAbility.loadContent('pages/Index')`
- but `main_pages.json` does not contain `pages/Index`
- or the intended startup page has already changed to another page such as `pages/CalculatorPage`

Typical symptom:

- project compiles successfully
- runtime opens to a white screen or does not show the intended first page

How to check:

1. Open `entry/src/main/ets/entryability/EntryAbility.ets`
2. Find the page passed to `windowStage.loadContent(...)`
3. Open `entry/src/main/resources/base/profile/main_pages.json`
4. Confirm the same page is registered there
5. Confirm this page is the intended startup page

Recommended fix:

- make `loadContent(...)` and `main_pages.json` agree on the same primary page
- remove stale template pages from the startup path
- if the real app starts from `CalculatorPage`, do not keep loading `pages/Index`

Important distinction:

- `EntryAbility.loadContent(...)` decides which registered page opens first
- `main_pages.json` declares which pages are valid registered pages
- these two must be aligned, but they are not interchangeable
- changing the startup page does not mean removing `@Entry` from every other registered page

## 2. Do Not Leave Multiple Main Pages Marked With `@Entry`

Problem pattern:

- several page files are annotated with `@Entry`
- while the app also uses `EntryAbility.loadContent(...)`

Typical symptom:

- startup behavior becomes ambiguous
- runtime behavior differs from expected page registration

Recommended fix:

- keep the startup decision centralized
- if the app uses `EntryAbility.loadContent(...)`, let it choose the startup page explicitly
- do not treat every `@Entry` page as the active startup page
- but do keep `@Entry` on pages that are declared in `main_pages.json`

Guardrail:

- every page listed in `main_pages.json` must have one and only one `@Entry`
- if `main_pages.json` lists `pages/CalculatorPage` and `pages/ConversionPage`, both page files must keep `@Entry`
- the fix for a wrong startup page is usually changing `EntryAbility.loadContent(...)`, not stripping `@Entry` from other registered pages

## 3. Skeleton Owns Shared Navigation Decisions

Problem pattern:

- page workers each invent their own tab switching or route mapping
- shared navigation files are added late or inconsistently

Typical symptom:

- compile may still pass
- tabs, route names, or page switching drift apart between pages

Recommended fix:

- skeleton must define shared navigation ownership early
- create the shared navigation component and route helper first
- page workers should consume these shared artifacts instead of redefining them

## 4. Compile Success Does Not Guarantee Runtime Safety

Problem pattern:

- imports and symbols compile
- but startup configuration still points at stale pages or stale navigation

Typical symptom:

- white screen
- wrong startup page
- tab clicks do nothing or navigate to missing pages

Verification checklist:

1. `EntryAbility.loadContent(...)` points to the intended page
2. `main_pages.json` contains the same page and all primary pages
3. route helper names match real page paths
4. navigation tabs map to registered pages only
5. stale template pages are not still used as startup targets
