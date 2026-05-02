module Etna.Gens.Hedgehog where

import           Hedgehog (Gen)
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

import Etna.Properties (DropFinalBlankArgs(..), UnintercalateArgs(..))

gen_drop_final_blank_empty_list :: Gen DropFinalBlankArgs
gen_drop_final_blank_empty_list = do
  delims <- Gen.string (Range.linear 1 2) (Gen.element "xy")
  input  <- Gen.string (Range.linear 0 6) (Gen.element "abxy")
  pure (DropFinalBlankArgs delims input)

gen_unintercalate_is_inverse_of_intercalate :: Gen UnintercalateArgs
gen_unintercalate_is_inverse_of_intercalate = do
  delim <- Gen.string (Range.linear 1 2) (Gen.element "xy")
  input <- Gen.string (Range.linear 0 8) (Gen.element "abxy")
  pure (UnintercalateArgs delim input)
