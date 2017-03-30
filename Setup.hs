{-# OPTIONS_GHC
  -Wall -Wno-warnings-deprecations -fno-warn-orphans -threaded -with-rtsopts=-N #-}
{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StandaloneDeriving #-}

import Data.Monoid ((<>))
import Distribution.Simple
       (defaultMain, UserHooks(..), defaultMainWithHooks, simpleUserHooks)
import Distribution.Simple.Setup
       (TestFlags(..), BenchmarkFlags(..))
import GHC.Environment (getFullArgs)
import System.Environment (lookupEnv)
import System.Log.FastLogger
       (defaultBufSize, LogStr, toLogStr, LogType(LogFileNoRotate),
        withTimedFastLogger)
import System.Log.FastLogger.Date (newTimeCache, simpleTimeFormat)
import Text.Show.Pretty (ppShow)

deriving instance Show TestFlags

deriving instance Show BenchmarkFlags

main :: IO ()
main = do
    logPath' <- lookupEnv "CABAL_LOGFILE"
    case logPath' of
        Nothing -> defaultMain
        Just logPath -> do
            tgetter <- newTimeCache simpleTimeFormat
            withTimedFastLogger tgetter (LogFileNoRotate logPath defaultBufSize) $ \tlog -> do
                let flog s =
                        tlog $ \ft ->
                            "[" <> toLogStr ft <> "] " <> toLogStr s <> "\n"
                args <- getFullArgs
                flog $ "Process args: " <> ppLog args
                let preHook n h x y = do
                        flog $ n <> " Args: " <> ppLog x
                        flog $ n <> " Flags: " <> ppLog y
                        r <- h simpleUserHooks x y
                        flog $ n <> " HookedBuildInfo: " <> ppLog r
                        pure r
                let hook4 n h x y z w = do
                        flog $ n <> " PackageDescription: " <> ppLog x
                        flog $ n <> " LocalBuildInfo: " <> ppLog y
                        flog $ n <> " Flags: " <> ppLog w
                        h simpleUserHooks x y z w
                let hook5 n h' a p i h f = do
                        flog $ n <> " Args: " <> ppLog a
                        flog $ n <> " PackageDescription: " <> ppLog p
                        flog $ n <> " LocalBuildInfo: " <> ppLog i
                        flog $ n <> " Flags: " <> ppLog f
                        h' simpleUserHooks a p i h f
                let postHook n h x y z w = do
                        flog $ n <> " Args: " <> ppLog x
                        flog $ n <> " Flags: " <> ppLog y
                        flog $ n <> " PackageDescription: " <> ppLog z
                        flog $ n <> " LocalBuildInfo: " <> ppLog w
                        h simpleUserHooks x y z w
                defaultMainWithHooks
                    simpleUserHooks
                    { runTests =
                          \a f p i -> do
                              flog $ "runTests Args: " <> ppLog a
                              flog $ "runTests flag: " <> ppLog f
                              flog $ "runTests PackageDescription: " <> ppLog p
                              flog $ "runTests LocalBuildInfo: " <> ppLog i
                              runTests simpleUserHooks a f p i
                    , readDesc =
                          do r <- readDesc simpleUserHooks
                             flog $ "readDesc: " <> ppLog r
                             pure r
                    , preConf = preHook "preConf" preConf
                    , confHook =
                          \(g, h) c -> do
                              flog $
                                  "confHook GenericPackageDescription: " <>
                                  ppLog g
                              flog $ "confHook HookedBuildInfo: " <> ppLog h
                              flog $ "confHook ConfigFlags: " <> ppLog c
                              i <- confHook simpleUserHooks (g, h) c
                              flog $ "confHook LocalBuildInfo: " <> ppLog i
                              pure i
                    , postConf = postHook "postConf" postConf
                    , preBuild = preHook "preBuild" preBuild
                    , buildHook = hook4 "buildHook" buildHook
                    , postBuild = postHook "postBuild" postBuild
                    , preRepl = preHook "preRepl" preRepl
                    , replHook =
                          \p i h f a -> do
                              flog $ "replHook PackageDescription: " <> ppLog p
                              flog $ "replHook LocalBuildInfo: " <> ppLog i
                              flog $ "replHook ReplFlags: " <> ppLog f
                              flog $ "replHook args: " <> ppLog a
                              replHook simpleUserHooks p i h f a
                    , postRepl = postHook "postRepl" postRepl
                    , preClean = preHook "preClean" preClean
                    , cleanHook = hook4 "cleanHook" cleanHook
                    , postClean = postHook "postClean" postClean
                    , preCopy = preHook "preCopy" preCopy
                    , copyHook = hook4 "copyHook" copyHook
                    , postCopy = postHook "postCopy" postCopy
                    , preInst = preHook "preInst" preInst
                    , instHook = hook4 "instHook" instHook
                    , postInst = postHook "postInst" postInst
                    , preSDist = preHook "preSDist" preSDist
                    , sDistHook = hook4 "sDistHook" sDistHook
                    , postSDist = postHook "postSDist" postSDist
                    , preReg = preHook "preReg" preReg
                    , regHook = hook4 "regHook" regHook
                    , postReg = postHook "postReg" postReg
                    , preUnreg = preHook "preUnreg" preUnreg
                    , unregHook = hook4 "unregHook" unregHook
                    , postUnreg = postHook "postUnreg" postUnreg
                    , preHscolour = preHook "preHscolour" preHscolour
                    , hscolourHook = hook4 "hscolourHook" hscolourHook
                    , postHscolour = postHook "postHscolour" postHscolour
                    , preHaddock = preHook "preHaddock" preHaddock
                    , haddockHook = hook4 "haddockHook" haddockHook
                    , postHaddock = postHook "postHaddock" postHaddock
                    , preTest = preHook "preTest" preTest
                    , testHook = hook5 "testHook" testHook
                    , postTest = postHook "postTest" postTest
                    , preBench = preHook "preBench" preBench
                    , benchHook = hook5 "benchHook" benchHook
                    , postBench = postHook "postBench" postBench
                    }
  where
    ppLog
        :: Show a
        => a -> LogStr
    ppLog = toLogStr . ppShow
