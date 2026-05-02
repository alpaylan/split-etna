{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import           Control.Exception     (SomeException, evaluate, try)
import           Data.IORef            (newIORef, readIORef, modifyIORef')
import           Data.Time.Clock       (diffUTCTime, getCurrentTime)
import           System.Environment    (getArgs)
import           System.Exit           (exitWith, ExitCode(..))
import           System.IO             (hFlush, stdout)
import           System.IO.Unsafe      (unsafePerformIO)
import           Text.Printf           (printf)

import           Etna.Result           (PropertyResult(..))
import qualified Etna.Properties       as P
import qualified Etna.Witnesses        as W
import qualified Etna.Gens.QuickCheck  as GQ
import qualified Etna.Gens.Hedgehog    as GH
import qualified Etna.Gens.Falsify     as GF
import qualified Etna.Gens.SmallCheck  as GS

import qualified Test.QuickCheck                    as QC
import qualified Hedgehog                           as HH
import qualified Test.Falsify.Generator             as FG
import qualified Test.Falsify.Interactive           as FI
import qualified Test.Falsify.Property              as FP
import qualified Test.SmallCheck                    as SC
import qualified Test.SmallCheck.Drivers             as SCD
import qualified Test.SmallCheck.Series              as SCS

allProperties :: [String]
allProperties =
  [ "DropFinalBlankEmptyList"
  , "UnintercalateIsInverseOfIntercalate"
  ]

data Outcome = Outcome
  { oStatus :: String
  , oTests  :: Int
  , oCex    :: Maybe String
  , oErr    :: Maybe String
  }

main :: IO ()
main = do
  argv <- getArgs
  case argv of
    [tool, prop] -> dispatch tool prop
    _            -> do
      putStrLn "{\"status\":\"aborted\",\"error\":\"usage: etna-runner <tool> <property>\"}"
      hFlush stdout
      exitWith (ExitFailure 2)

dispatch :: String -> String -> IO ()
dispatch tool prop
  | prop /= "All" && prop `notElem` allProperties =
      emit tool prop "aborted" 0 0 Nothing (Just $ "unknown property: " ++ prop)
  | otherwise = do
      let targets = if prop == "All" then allProperties else [prop]
      mapM_ (runOne tool) targets

runOne :: String -> String -> IO ()
runOne tool prop = do
  t0 <- getCurrentTime
  result <- try (driver tool prop) :: IO (Either SomeException Outcome)
  t1 <- getCurrentTime
  let us = round ((realToFrac (diffUTCTime t1 t0) :: Double) * 1e6) :: Int
  case result of
    Left e  -> emit tool prop "aborted" 0 us Nothing (Just (show e))
    Right (Outcome status tests cex err) ->
      emit tool prop status tests us cex err

driver :: String -> String -> IO Outcome
driver "etna"       p = runWitnesses p
driver "quickcheck" p = runQuickCheck p
driver "hedgehog"   p = runHedgehog   p
driver "falsify"    p = runFalsify    p
driver "smallcheck" p = runSmallCheck p
driver tool         _ = pure (Outcome "aborted" 0 Nothing (Just ("unknown tool: " ++ tool)))

------------------------------------------------------------------------------
-- Tool: etna (witness replay)
------------------------------------------------------------------------------

runWitnesses :: String -> IO Outcome
runWitnesses prop = case witnessesFor prop of
  []    -> pure (Outcome "aborted" 0 Nothing (Just ("no witnesses for " ++ prop)))
  cs    -> go cs 0
  where
    go [] n = pure (Outcome "passed" n Nothing Nothing)
    go ((name, r):rest) n = do
      forced <- try (evaluate r) :: IO (Either SomeException PropertyResult)
      case forced of
        Left e  -> pure (Outcome "failed" (n + 1) (Just name) (Just (show e)))
        Right Pass     -> go rest (n + 1)
        Right Discard  -> go rest (n + 1)
        Right (Fail m) -> pure (Outcome "failed" (n + 1) (Just name) (Just m))

-- | Force a property result inside pure code, catching runtime
-- exceptions thrown by the library-under-test. Used by the Falsify
-- adapter (which has no IO escape inside its 'Property' monad) and
-- conceptually mirrors the QC.ioProperty / HH.evalIO / SC.monadic
-- wrappers used by the other adapters.
safeEval :: PropertyResult -> Either String PropertyResult
safeEval pr = unsafePerformIO $ do
  r <- try (evaluate pr) :: IO (Either SomeException PropertyResult)
  pure $ case r of
    Left e  -> Left (show e)
    Right v -> Right v
{-# NOINLINE safeEval #-}

witnessesFor :: String -> [(String, PropertyResult)]
witnessesFor "DropFinalBlankEmptyList" =
  [ ( "witness_drop_final_blank_empty_list_case_empty"
    , W.witness_drop_final_blank_empty_list_case_empty )
  , ( "witness_drop_final_blank_empty_list_case_single_delim"
    , W.witness_drop_final_blank_empty_list_case_single_delim )
  ]
witnessesFor "UnintercalateIsInverseOfIntercalate" =
  [ ( "witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim"
    , W.witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim )
  , ( "witness_unintercalate_is_inverse_of_intercalate_case_abx"
    , W.witness_unintercalate_is_inverse_of_intercalate_case_abx )
  ]
witnessesFor _ = []

------------------------------------------------------------------------------
-- Tool: quickcheck
------------------------------------------------------------------------------

runQuickCheck :: String -> IO Outcome
runQuickCheck "DropFinalBlankEmptyList" =
  qcDrive (QC.forAll GQ.gen_drop_final_blank_empty_list
            (qcProp P.property_drop_final_blank_empty_list))
runQuickCheck "UnintercalateIsInverseOfIntercalate" =
  qcDrive (QC.forAll GQ.gen_unintercalate_is_inverse_of_intercalate
            (qcProp P.property_unintercalate_is_inverse_of_intercalate))
runQuickCheck p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

qcProp :: (a -> PropertyResult) -> a -> QC.Property
qcProp f args = QC.ioProperty $ do
  r <- try (evaluate (f args)) :: IO (Either SomeException PropertyResult)
  pure $ case r of
    Left e          -> QC.counterexample (show e) (QC.property False)
    Right Pass      -> QC.property True
    Right Discard   -> QC.discard
    Right (Fail m)  -> QC.counterexample m (QC.property False)

qcDrive :: QC.Property -> IO Outcome
qcDrive p = do
  result <- QC.quickCheckWithResult
              QC.stdArgs { QC.maxSuccess = 200, QC.chatty = False }
              p
  case result of
    QC.Success { QC.numTests = n } -> pure (Outcome "passed" n Nothing Nothing)
    QC.Failure { QC.numTests = n, QC.failingTestCase = tc } ->
      pure (Outcome "failed" n (Just (concat tc)) Nothing)
    QC.GaveUp  { QC.numTests = n } -> pure (Outcome "aborted" n Nothing (Just "QuickCheck gave up"))
    QC.NoExpectedFailure { QC.numTests = n } ->
      pure (Outcome "aborted" n Nothing (Just "no expected failure"))

------------------------------------------------------------------------------
-- Tool: hedgehog
------------------------------------------------------------------------------

runHedgehog :: String -> IO Outcome
runHedgehog "DropFinalBlankEmptyList" =
  hhDrive GH.gen_drop_final_blank_empty_list P.property_drop_final_blank_empty_list
runHedgehog "UnintercalateIsInverseOfIntercalate" =
  hhDrive GH.gen_unintercalate_is_inverse_of_intercalate
          P.property_unintercalate_is_inverse_of_intercalate
runHedgehog p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

hhDrive
  :: (Show a) => HH.Gen a -> (a -> PropertyResult) -> IO Outcome
hhDrive gen f = do
  let test = HH.property $ do
        args <- HH.forAll gen
        r <- HH.evalIO (try (evaluate (f args))
                          :: IO (Either SomeException PropertyResult))
        case r of
          Left e         -> do
            HH.annotate (show e)
            HH.failure
          Right Pass     -> pure ()
          Right Discard  -> HH.discard
          Right (Fail m) -> do
            HH.annotate m
            HH.failure
  ok <- HH.check test
  if ok
    then pure (Outcome "passed" 200 Nothing Nothing)
    else pure (Outcome "failed" 1 Nothing Nothing)

------------------------------------------------------------------------------
-- Tool: falsify
------------------------------------------------------------------------------

runFalsify :: String -> IO Outcome
runFalsify "DropFinalBlankEmptyList" =
  fsDrive GF.gen_drop_final_blank_empty_list P.property_drop_final_blank_empty_list
runFalsify "UnintercalateIsInverseOfIntercalate" =
  fsDrive GF.gen_unintercalate_is_inverse_of_intercalate
          P.property_unintercalate_is_inverse_of_intercalate
runFalsify p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

fsDrive
  :: (Show a)
  => FG.Gen a
  -> (a -> PropertyResult)
  -> IO Outcome
fsDrive gen f = do
  let prop = do
        args <- FP.gen gen
        case safeEval (f args) of
          Left e         -> FP.testFailed (show args ++ ": " ++ e)
          Right Pass     -> pure ()
          Right Discard  -> FP.discard
          Right (Fail m) -> FP.testFailed (show args ++ ": " ++ m)
  mFailure <- FI.falsify prop
  case mFailure of
    Nothing  -> pure (Outcome "passed" 100 Nothing Nothing)
    Just msg -> pure (Outcome "failed" 1 (Just msg) Nothing)

------------------------------------------------------------------------------
-- Tool: smallcheck
------------------------------------------------------------------------------

runSmallCheck :: String -> IO Outcome
runSmallCheck "DropFinalBlankEmptyList" =
  scDrive GS.series_drop_final_blank_empty_list
          P.property_drop_final_blank_empty_list
runSmallCheck "UnintercalateIsInverseOfIntercalate" =
  scDrive GS.series_unintercalate_is_inverse_of_intercalate
          P.property_unintercalate_is_inverse_of_intercalate
runSmallCheck p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

scDrive
  :: (Show a)
  => SCS.Series IO a
  -> (a -> PropertyResult)
  -> IO Outcome
scDrive series f = do
  countRef <- newIORef (0 :: Int)
  let depth = 4
      check args = SC.monadic $ do
        modifyIORef' countRef (+1)
        r <- try (evaluate (f args))
               :: IO (Either SomeException PropertyResult)
        pure $ case r of
          Left _         -> False
          Right Pass     -> True
          Right Discard  -> True
          Right (Fail _) -> False
      smTest = SC.over series check
  res <- try (SCD.smallCheckM depth smTest)
           :: IO (Either SomeException (Maybe SCD.PropertyFailure))
  n <- readIORef countRef
  case res of
    Left e          -> pure (Outcome "failed" n Nothing (Just (show e)))
    Right Nothing   -> pure (Outcome "passed" n Nothing Nothing)
    Right (Just pf) -> pure (Outcome "failed" n (Just (show pf)) Nothing)

------------------------------------------------------------------------------
-- Output (single JSON line, exit 0 except on argv error)
------------------------------------------------------------------------------

emit :: String -> String -> String -> Int -> Int -> Maybe String -> Maybe String -> IO ()
emit tool prop status tests us cex err = do
  let q = quoteJSON
      esc Nothing  = "null"
      esc (Just s) = q s
  printf "{\"status\":%s,\"tests\":%d,\"discards\":0,\"time\":\"%dus\",\"counterexample\":%s,\"error\":%s,\"tool\":%s,\"property\":%s}\n"
    (q status) tests us (esc cex) (esc err) (q tool) (q prop)
  hFlush stdout

quoteJSON :: String -> String
quoteJSON s = '"' : concatMap esc s ++ "\""
  where
    esc '"'  = "\\\""
    esc '\\' = "\\\\"
    esc '\n' = "\\n"
    esc '\r' = "\\r"
    esc '\t' = "\\t"
    esc c | fromEnum c < 0x20 = printf "\\u%04x" (fromEnum c)
          | otherwise = [c]
