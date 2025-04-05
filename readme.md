# The Unicode Tools Of Rexx (TUTOR)

The TUTOR package is hosted on:

- <https://rexx.epbcn.com/TUTOR/> (daily builds and releases).
- <https://github.com/JosepMariaBlasco/TUTOR/> (releases only).

The copy at <https://rexx.epbcn.com/TUTOR/> uses
the Rexx Highlighter to display Rexx programs, while
the copy at <https://github.com/JosepMariaBlasco/TUTOR/>
uses the (more limited) highlighting provided by GitHub.

TUTOR is also distributed as part of **net-oo-rexx**,
a software bundle curated by Rony Flatscher.
The net-oo-rexx package can be downloaded at
<https://wi.wu.ac.at/rgf/rexx/tmp/net-oo-rexx-packages/>.

---

Version 0.6a, 20250325, 20250405 refresh.

```
/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/TUTOR/                                          *
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

## Quick installation notes

Download [Tutor.zip](TUTOR.zip), unzip it in some directory of your choice,
and run `setenv` to set the path
(for Linux users: use `. ./setenv.sh`, not `./setenv.sh`, or your path will not be set).

If you intend to use RXU, the Rexx Preprocessor for Unicode, you will need to
download and install the Rexx Parser
(available at <https://rexx.epbcn.com/rexx-parser/> and <https://github.com/JosepMariaBlasco/rexx-parser/>)
and also run `setenv` in the parser installation directory.

You may prefer to use the net-oo-rexx bundle, available at
<https://wi.wu.ac.at/rgf/rexx/tmp/net-oo-rexx-packages/>,
which includes a copy of both TUTOR and the Rexx Package.
In that case, please follow the installation instructions
present in that package. You will then be able to use
TUTOR from a terminal shell, or by using **ooRexxShell**
a powerful, Swiss army knife shell developed by Jean Louis
Faucher; ooRexxShell includes integrated support for
TUTOR and for the Rexx parser.

You can then navigate to the `samples` directory and try the samples by using `[rexx] rxu filename`,
or experiment interactively with the `rxutry` utility, or with ooRexxShell.

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

## Release notes for version 0.6a, 20250215

Version 0.6a includes some small changes to allow running RXU,
the Rexx Preprocessor for Unicode, under Jean Louis Faucher's ooRexxShell
(thanks to Jean Louis for suggesting the changes).

## Components of TUTOR which can be used independently

* [The UTF8](bin/utf8.cls) routine can be used independently of TUTOR. UTF8 detects whether Unicode.cls has been loaded (by looking for the existence of a .Bytes class that subclasses .String), and returns .Bytes strings or standard ooRexx strings as appropriate.

---

## \[Cumulative change log since release 0.6a\]

+ 20250405 - Add references to net-oo-rexx and to ooRexxShell in the
appropriate places.

---

[Release notes for version 0.6a, 20250323](doc/0.6a-release-notes.md)<br>
[Release notes for version 0.6, 20250215](doc/0.6-release-notes.md)<br>
[Release notes for version 0.5, 20240307](doc/0.5-release-notes.md)<br>
[Release notes for version 0.4a, 20231002](doc/0.4a-release-notes.md)<br>
[Release notes for version 0.4, 20230901](doc/0.4-release-notes.md)<br>
[Release notes for version 0.3b, 20230817](doc/0.3b-release-notes.md)<br>
[Release notes for version 0.3, 20230811](doc/0.3-release-notes.md)<br>
[Release notes for version 0.2, 20230726](doc/0.2-release-notes.md)<br>
[Release notes for version 0.1d, 20230719](doc/0.1d-release-notes.md)<br>
[Release notes for version 0.1, 20230716](doc/0.1-release-notes.md)<br>
[A toy ooRexx implementation of the General_Category Unicode property (20230711)](doc/pre-0.1-release-notes.md)
