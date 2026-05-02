module Etna.Properties where

import Data.List (intercalate)
import Data.List.Split (dropFinalBlank, dropInitBlank, oneOf, split, unintercalate)

import Etna.Result

------------------------------------------------------------------------------
-- Variant 1: drop_final_blank_empty_list_6da4473_1
-- "Internals.hs: fix empty list bug with dropFinalBlank"
------------------------------------------------------------------------------

-- | A delimiter set plus an input list to feed to a splitter that
-- carries both 'dropInitBlank' and 'dropFinalBlank'. The historical
-- bug crashes via @last []@ whenever the list left over after
-- 'dropInitial' is empty (which happens for @input == []@ and for
-- inputs consisting of a single delimiter).
data DropFinalBlankArgs = DropFinalBlankArgs
  { dfbDelims :: !String
  , dfbInput  :: !String
  } deriving (Show, Eq)

-- | Property: 'split' with @dropFinalBlank . dropInitBlank@ must not
-- crash on any input. We force the result spine via 'length' so any
-- runtime exception inside the buggy 'dropFinal' (notably the
-- @last []@ crash on inputs that reduce to @[]@ after 'dropInitial')
-- surfaces as a counterexample, caught by the runner's exception
-- handler. A successful evaluation always returns 'Pass'; the bug
-- never returns a wrong answer, it only ever crashes.
property_drop_final_blank_empty_list :: DropFinalBlankArgs -> PropertyResult
property_drop_final_blank_empty_list (DropFinalBlankArgs delims input)
  | null delims = Discard
  | otherwise =
      let result = split (dropFinalBlank . dropInitBlank $ oneOf delims) input
          n      = length result
      in n `seq` Pass

------------------------------------------------------------------------------
-- Variant 2: unintercalate_inverse_82edf4e_1
-- "fix properties for unintercalate, add properties for splitEvery"
------------------------------------------------------------------------------

-- | A non-empty delimiter and an arbitrary input list. The historical
-- bug aliased 'unintercalate' to 'endBy', which strips a trailing
-- empty chunk and breaks the inverse property
-- @intercalate x . unintercalate x = id@ whenever the input ends in
-- the delimiter.
data UnintercalateArgs = UnintercalateArgs
  { uiDelim :: !String
  , uiInput :: !String
  } deriving (Show, Eq)

-- | Property: @intercalate x . unintercalate x@ is the identity. With
-- the buggy @unintercalate = endBy@ the inverse fails for any input
-- ending in the delimiter.
property_unintercalate_is_inverse_of_intercalate :: UnintercalateArgs -> PropertyResult
property_unintercalate_is_inverse_of_intercalate (UnintercalateArgs delim input)
  | null delim = Discard
  | otherwise =
      let recovered = intercalate delim (unintercalate delim input)
      in if recovered == input
           then Pass
           else Fail $
             "intercalate " ++ show delim ++ " (unintercalate "
               ++ show delim ++ " " ++ show input ++ ") = "
               ++ show recovered ++ " /= " ++ show input
