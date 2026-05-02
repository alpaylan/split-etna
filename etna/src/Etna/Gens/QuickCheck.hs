module Etna.Gens.QuickCheck where

import qualified Test.QuickCheck as QC

import Etna.Properties (DropFinalBlankArgs(..), UnintercalateArgs(..))

-- | Small alphabets keep the search space tractable while still
-- exercising the empty-input crash and the trailing-delimiter cases
-- the historical bugs depend on.
gen_drop_final_blank_empty_list :: QC.Gen DropFinalBlankArgs
gen_drop_final_blank_empty_list = do
  delimsLen <- QC.choose (1, 2)
  delims <- QC.vectorOf delimsLen (QC.elements "xy")
  inputLen <- QC.choose (0, 6)
  input <- QC.vectorOf inputLen (QC.elements "abxy")
  pure (DropFinalBlankArgs delims input)

gen_unintercalate_is_inverse_of_intercalate :: QC.Gen UnintercalateArgs
gen_unintercalate_is_inverse_of_intercalate = do
  delimLen <- QC.choose (1, 2)
  delim <- QC.vectorOf delimLen (QC.elements "xy")
  inputLen <- QC.choose (0, 8)
  input <- QC.vectorOf inputLen (QC.elements "abxy")
  pure (UnintercalateArgs delim input)
