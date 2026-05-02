module Main where

import Etna.Result (PropertyResult(..))
import Etna.Witnesses
  ( witness_drop_final_blank_empty_list_case_empty
  , witness_drop_final_blank_empty_list_case_single_delim
  , witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim
  , witness_unintercalate_is_inverse_of_intercalate_case_abx
  )
import System.Exit (exitFailure, exitSuccess)

cases :: [(String, PropertyResult)]
cases =
  [ ( "witness_drop_final_blank_empty_list_case_empty"
    , witness_drop_final_blank_empty_list_case_empty )
  , ( "witness_drop_final_blank_empty_list_case_single_delim"
    , witness_drop_final_blank_empty_list_case_single_delim )
  , ( "witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim"
    , witness_unintercalate_is_inverse_of_intercalate_case_trailing_delim )
  , ( "witness_unintercalate_is_inverse_of_intercalate_case_abx"
    , witness_unintercalate_is_inverse_of_intercalate_case_abx )
  ]

main :: IO ()
main = do
  let failures =
        [ (n, msg) | (n, Fail msg) <- cases ] ++
        [ (n, "discard") | (n, Discard) <- cases ]
  if null failures
    then do
      putStrLn $ "OK: all " ++ show (length cases) ++ " witnesses passed"
      exitSuccess
    else do
      mapM_ (\(n, m) -> putStrLn (n ++ ": FAIL: " ++ m)) failures
      exitFailure
