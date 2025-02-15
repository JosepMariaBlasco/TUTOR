# The Unicode Tools Of Rexx (TUTOR)

Version 0.5, 20240307.

```
/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/tutor/                                          *
 *     and https://github.com/JosepMariaBlasco/TUTOR                          *
 * Copyright © 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>    *
 * License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  *
 ******************************************************************************/
```

```
/******************************************************************************
 * => TUTOR is a prototype, not a finished product. Use at your own risk. <═  *
 *                                                                            *
 *      Interfaces and specifications are proposals to be discussed,          *
 *       and can be changed at any moment without previous notice.            *
 ******************************************************************************/
```

---

## Quick installation

Download Unicode.zip, unzip it in some directory of your choice, and run ``setenv`` to set the path (for Linux users: use ``. ./setenv.sh``, not ``./setenv.sh``, or your path will not be set).

You can then navigate to the ``samples`` directory and try the samples by using ``[rexx] rxu filename``, or experiment interactively with the ``rxutry`` utility.

## Documentation

* [For The Unicode Tools Of Rexx (TUTOR, this file)](.).
* [For RXU, the Rexx Preprocessor for Unicode](./doc/rxu/)
  * [New types of strings](./doc/string-types/)
  * [Revised built-in functions](./doc/built-in/)
    * [Stream functions for Unicode](./doc/stream/)
    * [The encoding/decoding model](./doc/encodings/)
  * [New built-in functions](./doc/new-functions/)
    * [The properties model](./doc/properties/)
      * [The Unicode.Normalization class](./doc/properties/normalization/).
  * [New classes](./doc/new-classes/)
  * [New values for the OPTIONS instruction](./doc/options/)
  * Utility packages
    * [The MultiStageTable class](./doc/multi-stage-table/)
    * [The PersistentStringTable class](./doc/persistent-string-table/)
* [Using TUTOR from Classic Rexx](./doc/using-tutor-from-classic-rexx/)

## Release notes for version 0.5, 20240307

New and changed features in the 0.5 release are:

* Implementations of NFC normalization (``toNFC`` and ``isNFC`` functions).
* Addition of a new GRAPHEMES string type. TEXT auto-normalizes to NFC at creation time (this includes the results of operations and built-ins), while GRAPHEMES does perform any automatical normalization. Both GRAPHEMES and TEXT can be used as targets when opening a Unicode-enabled stream.
* Implement loose matching for property names (UNICODE BIF).
* Implement all tests in NormalizationTest.txt, consistency check on ccc and canonical decomposition.
* InspectTokens: add options to select different dialects, specify default in the help display.
* New ``rxutry.rex`` utility, a modification of ``rexxtry.rex`` with Unicode support.
* ``Options DefaultString`` and ``Options Promote`` can be set by the caller. Make Options DefaultString TEXT the default.
* Added [a new helpfile](doc/using-tutor-from-classic-rexx/) detailing how to use some of the TUTOR-generated data files from Classic Rexx dialects like Regina.

Bugs fixed:

* Fix [bug #6](https://github.com/RexxLA/rexx-repository/issues/6)
* RXU: do not translate BIF names after a twiddle.

Documentation additions and enhancements:

* Document [the Unicode.Normalization class](doc/properties/normalization/).
* Document many of the properties currently implemented by the UNICODE BIF.
* Move notes for old releases to separate files in the ``doc`` subdirectory.
* Improve the docs for the PersistentStringTable class, and move them to [a separate helpfile](doc/persistent-string-table/).

## Components of TUTOR which can be used independently

There are currently two components of TUTOR which can be used independently of TUTOR, since they have no absolute dependencies on other TUTOR components.

* [The Rexx Tokenizer](https://rexx.epbcn.com/tokenizer/) can be used independently of TUTOR, but you will need TUTOR
  when you use one of the Unicode subclasses.
* [The UTF8](utf8.cls) routine can be used independently of TUTOR. UTF8 detects whether Unicode.cls has been loaded (by looking for the existence of a .Bytes class that subclasses .String), and returns .Bytes strings or standard ooRexx strings as appropriate.

---

## \[Cumulative change log since release 0.5\]

* 20240326 &mdash; Update all BIF railroad diagrams, add some new for STREAM ENCODING
* 20240325 &mdash; Update tokenizer constants, in preparation for clauser
* 20240325 &mdash; Start working on new railroad diagrams, using the same tools as in rexxref. First document migrated: new BIFS
* 20240323 &mdash; Fix https://github.com/RexxLA/rexx-repository/issues/7
* 20240323 &mdash; Implement the STRINGTYPE BIM, fixing https://github.com/RexxLA/rexx-repository/issues/9
* 20240323 &mdash; U2C was left undocumented in 0.5.
* 20240323 &mdash; Create the [publications](publications) subdirectory.
* 20240323 &mdash; Create [0.5-release-notes.md](doc/0.5-release-notes.md).
* 20240323 &mdash; Tokenizer: SPECIAL --> COMMA (all other special characters already handled separately).

---

[Release notes for version 0.5, 20240307](doc/0.5-release-notes.md)<br>
[Release notes for version 0.4a, 20231002](doc/0.4a-release-notes.md)<br>
[Release notes for version 0.4, 20230901](doc/0.4-release-notes.md)<br>
[Release notes for version 0.3b, 20230817](doc/0.3b-release-notes.md)<br>
[Release notes for version 0.3, 20230811](doc/0.3-release-notes.md)<br>
[Release notes for version 0.2, 20230726](doc/0.2-release-notes.md)<br>
[Release notes for version 0.1d, 20230719](doc/0.1d-release-notes.md)<br>
[Release notes for version 0.1, 20230716](doc/0.1-release-notes.md)<br>
[A toy ooRexx implementation of the General_Category Unicode property (20230711)](doc/pre-0.1-release-notes.md)
