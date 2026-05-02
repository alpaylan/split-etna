module Etna.Witnesses where

import Etna.Properties
import Etna.Result

------------------------------------------------------------------------------
-- Variant 1: drop_final_blank_empty_list_6da4473_1
------------------------------------------------------------------------------

-- | Empty input always crashes the buggy 'dropFinal' via @last []@.
witness_drop_final_blank_empty_list_case_empty :: PropertyResult
witness_drop_final_blank_empty_list_case_empty =
  property_drop_final_blank_empty_list (DropFinalBlankArgs "x" "")

-- | A single-delimiter input also reduces to @[]@ inside 'dropFinal'
-- after both 'dropInitBlank' and 'dropFinalBlank' fire.
witness_drop_final_blank_empty_list_case_single_delim :: PropertyResult
witness_drop_final_blank_empty_list_case_single_delim =
  property_drop_final_blank_empty_list (DropFinalBlankArgs "x" "x")

------------------------------------------------------------------------------
-- Variant 2: unintercalate_inverse_82edf4e_1
------------------------------------------------------------------------------

-- | Smallest input that ends in the delimiter: @"ax"@ with @"x"@.
-- Buggy 'unintercalate' returns @["a"]@; @intercalate "x" ["a"] = "a"@.
witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim :: PropertyResult
witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim =
  property_unintercalate_is_inverse_of_intercalate (UnintercalateArgs "x" "ax")

-- | Multi-character input ending in the delimiter.
witness_unintercalate_is_inverse_of_intercalate_case_abx :: PropertyResult
witness_unintercalate_is_inverse_of_intercalate_case_abx =
  property_unintercalate_is_inverse_of_intercalate (UnintercalateArgs "x" "abx")
