module Etna.Gens.Falsify where

import           Data.List.NonEmpty (NonEmpty(..))
import qualified Test.Falsify.Generator as F
import qualified Test.Falsify.Range as FR

import Etna.Properties (DropFinalBlankArgs(..), UnintercalateArgs(..))

ne :: [a] -> NonEmpty a
ne []     = error "Etna.Gens.Falsify.ne: empty list"
ne (x:xs) = x :| xs

gen_drop_final_blank_empty_list :: F.Gen DropFinalBlankArgs
gen_drop_final_blank_empty_list = do
  let delimChars = ne "xy"
      inputChars = ne "abxy"
  delims <- F.list (FR.between (1 :: Word, 2)) (F.elem delimChars)
  input  <- F.list (FR.between (0 :: Word, 6)) (F.elem inputChars)
  pure (DropFinalBlankArgs delims input)

gen_unintercalate_is_inverse_of_intercalate :: F.Gen UnintercalateArgs
gen_unintercalate_is_inverse_of_intercalate = do
  let delimChars = ne "xy"
      inputChars = ne "abxy"
  delim <- F.list (FR.between (1 :: Word, 2)) (F.elem delimChars)
  input <- F.list (FR.between (0 :: Word, 8)) (F.elem inputChars)
  pure (UnintercalateArgs delim input)
