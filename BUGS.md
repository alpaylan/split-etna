# split — Injected Bugs

Brent Yorgey's `split` package (byorgey/split). Bug fixes mined from upstream history; modern HEAD is the base, each patch reverse-applies a fix to install the original bug.

Total mutations: 2

## Bug Index

| # | Variant | Name | Location | Injection | Fix Commit |
|---|---------|------|----------|-----------|------------|
| 1 | `drop_final_blank_empty_list_6da4473_1` | `drop_final_blank_crashes_on_empty_input` | `src/Data/List/Split/Internals.hs:247` | `patch` | `6da4473ce648485317c613b84c8a327a796f8496` |
| 2 | `unintercalate_inverse_82edf4e_1` | `unintercalate_endBy_loses_trailing_chunk` | `src/Data/List/Split/Internals.hs:532` | `patch` | `82edf4e8af6b20f43567e7448ce106470d3ec015` |

## Property Mapping

| Variant | Property | Witness(es) |
|---------|----------|-------------|
| `drop_final_blank_empty_list_6da4473_1` | `DropFinalBlankEmptyList` | `witness_drop_final_blank_empty_list_case_empty`, `witness_drop_final_blank_empty_list_case_single_delim` |
| `unintercalate_inverse_82edf4e_1` | `UnintercalateIsInverseOfIntercalate` | `witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim`, `witness_unintercalate_is_inverse_of_intercalate_case_abx` |

## Framework Coverage

| Property | quickcheck | hedgehog | falsify | smallcheck |
|----------|---------:|-------:|------:|---------:|
| `DropFinalBlankEmptyList` | ✓ | ✓ | ✓ | ✓ |
| `UnintercalateIsInverseOfIntercalate` | ✓ | ✓ | ✓ | ✓ |

## Bug Details

### 1. drop_final_blank_crashes_on_empty_input

- **Variant**: `drop_final_blank_empty_list_6da4473_1`
- **Location**: `src/Data/List/Split/Internals.hs:247` (inside `dropFinal`)
- **Property**: `DropFinalBlankEmptyList`
- **Witness(es)**:
  - `witness_drop_final_blank_empty_list_case_empty` — split (dropFinalBlank . dropInitBlank $ oneOf "x") "" must not crash
  - `witness_drop_final_blank_empty_list_case_single_delim` — split (dropFinalBlank . dropInitBlank $ oneOf "x") "x" must not crash
- **Source**: internal — Internals.hs: fix empty list bug with dropFinalBlank
  > Pre-fix `dropFinal` was `dropFinal DropBlank l | Text [] <- last l = init l; dropFinal _ l = l`. Calling it with an empty `SplitList` (which happens whenever the input becomes empty after `dropInitial`, e.g. for `split (dropFinalBlank . dropInitBlank $ oneOf x) ""`) crashes with `Prelude.last: empty list`. The fix added a `dropFinal _ [] = []` guard. A later refactor (cbc3c5f, space leak) rewrote `dropFinal` to use a recursive helper and independently handles the empty case via `dropFinal' [] = []`; the synthesized patch reverts both safety nets to recreate the historical crash on modern HEAD.
- **Fix commit**: `6da4473ce648485317c613b84c8a327a796f8496` — Internals.hs: fix empty list bug with dropFinalBlank
- **Invariant violated**: `split (dropFinalBlank . dropInitBlank $ oneOf delims) input` must not crash and must return at most `length input + 1` chunks for any non-empty `delims` and any `input`.
- **How the mutation triggers**: Reverse-applying the patch swaps the modern guarded helper for the historical `last/init` formulation. Calling the splitter with `input = ""` (or any input that reduces to `[]` after `dropInitial`) then evaluates `last []`, which raises `Prelude.last: empty list`.

### 2. unintercalate_endBy_loses_trailing_chunk

- **Variant**: `unintercalate_inverse_82edf4e_1`
- **Location**: `src/Data/List/Split/Internals.hs:532` (inside `unintercalate`)
- **Property**: `UnintercalateIsInverseOfIntercalate`
- **Witness(es)**:
  - `witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim` — intercalate "x" (unintercalate "x" "ax") must equal "ax"
  - `witness_unintercalate_is_inverse_of_intercalate_case_abx` — intercalate "x" (unintercalate "x" "abx") must equal "abx"
- **Source**: internal — fix properties for unintercalate, add properties for splitEvery
  > Pre-fix `unintercalate = endBy`. `endBy` strips the trailing empty chunk that follows a final delimiter, so the inverse property `intercalate x . unintercalate x = id` fails for any input ending in the delimiter (e.g. `unintercalate "x" "ax"` returned `["a"]` instead of `["a",""]`). The fix swapped to `sepBy` (the modern `splitOn`); the patch reverts to the historical `endBy` form.
- **Fix commit**: `82edf4e8af6b20f43567e7448ce106470d3ec015` — fix properties for unintercalate, add properties for splitEvery
- **Invariant violated**: `intercalate delim (unintercalate delim input) == input` for every non-empty `delim` and arbitrary `input`.
- **How the mutation triggers**: Reverse-applying the patch reassigns `unintercalate = endBy`. For any input ending in the delimiter (e.g. `"ax"` with `"x"`) the recovered list omits the trailing empty chunk, so `intercalate` does not reproduce the original input.
