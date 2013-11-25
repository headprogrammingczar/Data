module Paths_data_eval (
    version,
    getBinDir, getLibDir, getDataDir, getLibexecDir,
    getDataFileName
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
catchIO = Exception.catch


version :: Version
version = Version {versionBranch = [0,1], versionTags = []}
bindir, libdir, datadir, libexecdir :: FilePath

bindir     = "/usr/local/bin"
libdir     = "/usr/local/lib/data-eval-0.1/ghc-7.4.1"
datadir    = "/usr/local/share/data-eval-0.1"
libexecdir = "/usr/local/libexec"

getBinDir, getLibDir, getDataDir, getLibexecDir :: IO FilePath
getBinDir = catchIO (getEnv "data_eval_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "data_eval_libdir") (\_ -> return libdir)
getDataDir = catchIO (getEnv "data_eval_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "data_eval_libexecdir") (\_ -> return libexecdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
