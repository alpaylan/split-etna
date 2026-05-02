# split (ETNA workload)

Workload built from [`byorgey/split`](https://github.com/byorgey/split)
(Brent Yorgey's `Data.List.Split`). Mining the upstream history yielded
two real correctness bugs, each shipped here as a single-file
`patches/<variant>.patch` that reverse-applies a fix to install the
original bug. Modern HEAD is the base; the runner package
(`etna/etna-runner.cabal`) adapts each property to QuickCheck,
Hedgehog, Falsify, and SmallCheck.

## Variants

| Variant | Property | Source-of-bug commit |
|---|---|---|
| `drop_final_blank_empty_list_6da4473_1` | `DropFinalBlankEmptyList` | [`6da4473`](https://github.com/byorgey/split/commit/6da4473ce648485317c613b84c8a327a796f8496) |
| `unintercalate_inverse_82edf4e_1` | `UnintercalateIsInverseOfIntercalate` | [`82edf4e`](https://github.com/byorgey/split/commit/82edf4e8af6b20f43567e7448ce106470d3ec015) |

Both `Internals.hs` patches were hand-synthesized against modern HEAD
because the upstream tree had drifted significantly since the original
fix commits. The synthesized patches recreate the historical buggy
behaviour faithfully — `dropFinal []` crashes via `last []`,
`unintercalate "x" "ax"` returns `["a"]` instead of `["a",""]`. Other
"fix" commits in the upstream history were dropped because they were
documentation-only, build/CI/GHC-compat fixes, or laziness/space-leak
improvements that do not surface as Pass/Fail PBT counterexamples
(`cbc3c5f`, `4baecb9`, `4f297b8`, `99ef17f`, `6b9fa79`, `d83db0c`).

## How to run

```sh
cd workloads/Haskell/split/etna
cabal build exe:etna-runner
cabal run -v0 etna-runner -- quickcheck DropFinalBlankEmptyList
cabal run -v0 etna-runner -- hedgehog   UnintercalateIsInverseOfIntercalate
# etc. — backends: quickcheck | hedgehog | falsify | smallcheck | etna
```

The runner emits a single JSON line per invocation and exits 0 except
on argv-parse errors, matching the etna `log_process_output` contract.

## Validate

```sh
cd workloads/Haskell/split
cabal test etna-witnesses                                    # base witnesses pass
git apply -R --whitespace=nowarn patches/<variant>.patch     # install bug
cabal test etna-witnesses                                    # base witnesses now FAIL
git apply    --whitespace=nowarn patches/<variant>.patch     # restore base
python ../../../scripts/check_haskell_workload.py .          # manifest/source consistency
```

## GHC toolchain

Pinned to GHC 9.6.6 (Falsify ≥ 0.2 needs `base >= 4.18`). The
`cabal.project` carries a `with-compiler` line pointing at
`/Users/akeles/.ghcup/ghc/9.6.6/bin/ghc-9.6.6`; adjust that path if
running on a different machine.
