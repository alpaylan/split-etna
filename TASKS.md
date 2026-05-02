# split — ETNA Tasks

Total tasks: 8

## Task Index

| Task | Variant | Framework | Property | Witness |
|------|---------|-----------|----------|---------|
| 001 | `drop_final_blank_empty_list_6da4473_1` | quickcheck | `DropFinalBlankEmptyList` | `witness_drop_final_blank_empty_list_case_empty` |
| 002 | `drop_final_blank_empty_list_6da4473_1` | hedgehog | `DropFinalBlankEmptyList` | `witness_drop_final_blank_empty_list_case_empty` |
| 003 | `drop_final_blank_empty_list_6da4473_1` | falsify | `DropFinalBlankEmptyList` | `witness_drop_final_blank_empty_list_case_empty` |
| 004 | `drop_final_blank_empty_list_6da4473_1` | smallcheck | `DropFinalBlankEmptyList` | `witness_drop_final_blank_empty_list_case_empty` |
| 005 | `unintercalate_inverse_82edf4e_1` | quickcheck | `UnintercalateIsInverseOfIntercalate` | `witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim` |
| 006 | `unintercalate_inverse_82edf4e_1` | hedgehog | `UnintercalateIsInverseOfIntercalate` | `witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim` |
| 007 | `unintercalate_inverse_82edf4e_1` | falsify | `UnintercalateIsInverseOfIntercalate` | `witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim` |
| 008 | `unintercalate_inverse_82edf4e_1` | smallcheck | `UnintercalateIsInverseOfIntercalate` | `witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim` |

## Witness Catalog

- `witness_drop_final_blank_empty_list_case_empty` — split (dropFinalBlank . dropInitBlank $ oneOf "x") "" must not crash
- `witness_drop_final_blank_empty_list_case_single_delim` — split (dropFinalBlank . dropInitBlank $ oneOf "x") "x" must not crash
- `witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim` — intercalate "x" (unintercalate "x" "ax") must equal "ax"
- `witness_unintercalate_is_inverse_of_intercalate_case_abx` — intercalate "x" (unintercalate "x" "abx") must equal "abx"
