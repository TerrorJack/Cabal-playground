# Cabal-playground

[![Build Status](https://travis-ci.org/TerrorJack/Cabal-playground.svg)](https://travis-ci.org/TerrorJack/Cabal-playground)

This repo contains a dummy `Cabal` project with a custom `Setup.hs` script which logs all parameters & return values of [`Simple`](https://hackage.haskell.org/package/Cabal-1.24.2.0/docs/Distribution-Simple.html) hooks to a text file. It contains a dummy library, executable, test-suite, benchmark and C source file.

Simply set the `$CABAL_LOGFILE` environment variable, and after the build completes, read the log and `grep` it to find info you may be interested in. If `$CABAL_LOGFILE` is not present, `setup` behaves like ordinary `Simple` builder. If you're using `cabal` instead of `stack` to build, first use `hpack` or `stack` to generate a `.cabal` file from `package.yaml`.

The log file contains entries like:

~~~
[30/Mar/2017:19:24:57 +0800] Process args: ...
...
[30/Mar/2017:19:24:57 +0800] preConf Flags: ...
...
~~~

Each entry is tagged with time and source. Entries may be multi-line, because they're pretty-printed before logging. `Process args` marks the launch of the `setup` process; other entries are the intercepted parameters/return values of hooks; consult the [`Setup.hs`](Setup.hs) file for details.

## Why?

The Haskell build system is a complicated beast. Above `ghc` we have `Cabal`, above `Cabal` we have `stack`/`cabal-install`, and even above that we have Docker/Nix to assist us (that's a separate story and not our concerns here).

For beginners, simple `stack`/`cabal` commands suffice to create & manage Haskell projects, the details are well hidden. The `Cabal` complexity beast jumps up and bites you when you begin to roll up your sleeves for some nasty work, examples I've encountered myself:

* Ship a complex C/C++ library and build them. `Cabal` only supports building C sources that doesn't need complex make rules (like generating intermediate C code, etc)
* Generate Haskell modules and export them. As the official mechanism of code generation, Template Haskell does not support manipulating modules yet, and it doesn't support annotating output with haddock documentation.

At such times, you need to hack the default `Cabal` build process. Fortunately, `Cabal` provides a hooks mechanism which allow triggering user-provided callbacks before/during/after `configure`/`build`/.. , and it's already used by numerous packages.

Using `Cabal` hooks tests one's understanding on how `ghc` and `Cabal` works: which processes are called, what flags are passed, what files are generated/modified, etc. There isn't a single textbook on this; the documentation is pretty scattered and incomplete; and even worse, `Cabal` hooks aren't well-documented; they even behave **differently** with `stack`/`cabal-install`! Stepping into these dark corners to make thing work is a time-consuming & painful experience for novice/intermediate Haskellers. (well, at least in my case)

So I wrote this little project which gets you a nice glimpse into how `Cabal` works. You're also welcome to adapt the `Setup.hs` script to your own project to help you debug the `Cabal` build process.
