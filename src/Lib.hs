module Lib
    ( action
    ) where

import Foreign.C.Types (CInt(..))

foreign import ccall safe "greetings_from_int" c_greetings_from_int
               :: CInt -> IO ()

action :: IO ()
action = c_greetings_from_int 233
