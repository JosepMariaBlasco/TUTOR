/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/TUTOR/                                          *
 *     and https://github.com/JosepMariaBlasco/TUTOR                          *
 * Copyright © 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>    *
 * License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  *
 ******************************************************************************/

--------------------------------------------------------------------------------
-- This program is part of the automated test suite. See tests/test.all.rex   --
--------------------------------------------------------------------------------

-- graphemes_utf8proc.rex - Validates the utf8proc grapheme-segmentation route
-- of the Graphemes class against the OFFICIAL Unicode GraphemeBreakTest.
--
-- When the utf8proc binding is present, Graphemes~init segments via utf8proc's
-- graphemeBreak (see Unicode.cls). utf8proc here is Unicode 17, so the oracle
-- is GraphemeBreakTest-17.0.0.txt (NOT the 15.0 file, against which utf8proc
-- would show spurious version-divergences: the new indic-aksara rules and the
-- reclassification of some Extended_Pictographic codepoints).
--
-- Each test line lists codepoints separated by ÷ (break) and × (no break).
-- The number of grapheme clusters expected is (number of ÷) - 1. We build the
-- UTF-8 string, run it through Graphemes, and check the cluster count AND the
-- exact cluster boundaries.
--
-- Gated on the binding: without it this route is not taken, so we skip.
-- Requires utf8proc at Unicode 17 (the bundled oracle's version).

  Call "Unicode.cls"

  If \ .RexxUnicodeServices~isA(.Class) Then Do
    Say "graphemes_utf8proc.rex: no utf8proc binding present; skipping."
    Exit 0
  End

  expectedUnicode = "17.0.0"
  haveUnicode     = .RexxUnicodeServices~unicodeVersion
  If haveUnicode \== expectedUnicode Then Do
    Say "graphemes_utf8proc.rex: binding is Unicode '"haveUnicode"', oracle is"
    Say expectedUnicode". Refusing to run to avoid spurious version-divergences."
    Exit 1
  End

  -- Resolve the oracle path robustly (independent of the current directory),
  -- relative to THIS test file's own directory (tests/beta/). The U17 files are
  -- oracles, not code inputs, so they live alongside the tests, not bin/UCD/.
  oracleDir = .File~new(.context~package~name)~parent
  oracle    = oracleDir || .File~separator || "GraphemeBreakTest-"expectedUnicode".txt"

  Call Time "R"
  Say "Validating utf8proc grapheme segmentation against the official"
  Say "GraphemeBreakTest-"expectedUnicode".txt (via the Graphemes class)..."
  Say

  lineNo = 0
  tested = 0
  Do While Lines(oracle) > 0
    line = LineIn(oracle)
    lineNo += 1
    If line == "" Then Iterate
    If Left(line, 1) == "#" Then Iterate

    Parse Var line testPart "#" .
    testPart = Strip(testPart)
    If testPart == "" Then Iterate

    -- Parse the ÷/× marks into: list of codepoints, and expected boundaries.
    -- expectedCounts = sizes (in codepoints) of each expected cluster.
    cps           = .Array~new
    clusterSizes  = .Array~new
    currentSize   = 0
    Do token Over testPart~makeArray(" ")
      Select
        When token == "÷" Then Do
          If currentSize > 0 Then clusterSizes~append(currentSize)
          currentSize = 0
        End
        When token == "×" Then Nop
        Otherwise Do
          cps~append(token)
          currentSize += 1
        End
      End
    End
    If cps~items == 0 Then Iterate

    -- Build the UTF-8 string from the codepoints.
    bytes = ""
    Do hx Over cps
      bytes ||= .RexxUnicodeServices~utf8EncodeCodepoint(X2D(hx), .MutableBuffer~new, >sz)~string
    End

    g = .Graphemes~new(bytes)
    tested += 1

    -- Check cluster count.
    If g~length \== clusterSizes~items Then
      Return Fail(lineNo, testPart, "cluster count" clusterSizes~items "expected," g~length "got")

    -- Check exact boundaries: rebuild expected clusters and compare bytes.
    cpIndex = 1
    Do k = 1 To clusterSizes~items
      expected = ""
      Do clusterSizes[k]
        expected ||= .RexxUnicodeServices~utf8EncodeCodepoint(X2D(cps[cpIndex]), .MutableBuffer~new, >sz)~string
        cpIndex += 1
      End
      If g[k]~makeString \== expected Then
        Return Fail(lineNo, testPart, "cluster" k "boundary mismatch")
    End
  End

  If tested == 0 Then Do
    Say "FAIL: no test lines were read from the oracle."
    Say "Expected to find: "oracle
    Exit 1
  End

  Say "Checked" tested "test lines, 0 failures."
  Say "Elapsed:" Time("E")"s."

Exit 0

Fail: Procedure
  Use Strict Arg lineNo, testPart, why
  Say "FAIL at line" lineNo": '"testPart"'"
  Say "  "why
Return 1
