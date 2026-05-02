{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Etna.Gens.SmallCheck where

import qualified Test.SmallCheck.Series as SC

import Etna.Properties (DropFinalBlankArgs(..), UnintercalateArgs(..))

-- | SmallCheck enumerates by depth. The empty-list crash for the
-- dropFinalBlank bug appears at depth 0 (input @""@); we keep the
-- alphabets tiny so depth 4 still fits in a few thousand cases.
series_drop_final_blank_empty_list :: Monad m => SC.Series m DropFinalBlankArgs
series_drop_final_blank_empty_list = do
  delimsLen <- SC.generate (\d -> [1 .. min (d + 1) 2])
  inputLen  <- SC.generate (\d -> [0 .. min (d + 0) 4])
  delims <- replicateA delimsLen (SC.generate (\_ -> "xy"))
  input  <- replicateA inputLen  (SC.generate (\_ -> "ax"))
  pure (DropFinalBlankArgs delims input)
  where
    replicateA :: Applicative f => Int -> f a -> f [a]
    replicateA 0 _ = pure []
    replicateA k f = (:) <$> f <*> replicateA (k - 1) f

series_unintercalate_is_inverse_of_intercalate :: Monad m => SC.Series m UnintercalateArgs
series_unintercalate_is_inverse_of_intercalate = do
  delimLen <- SC.generate (\d -> [1 .. min (d + 1) 2])
  inputLen <- SC.generate (\d -> [0 .. min (d + 0) 5])
  delim <- replicateA delimLen (SC.generate (\_ -> "xy"))
  input <- replicateA inputLen (SC.generate (\_ -> "ax"))
  pure (UnintercalateArgs delim input)
  where
    replicateA :: Applicative f => Int -> f a -> f [a]
    replicateA 0 _ = pure []
    replicateA k f = (:) <$> f <*> replicateA (k - 1) f
