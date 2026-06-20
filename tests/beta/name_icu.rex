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

-- name_icu.rex - Validates the Name (na) property against the OFFICIAL Unicode
-- UCD file UnicodeData-17.0.0.txt (field 2), NOT against a re-derived value.
--
-- WHY THIS TEST EXISTS, AND WHY IT IS SEPARATE FROM UnicodeData.rex:
-- Name is the ONE UCD property that utf8proc does NOT expose. It is served by
-- the ICU layer (ICU4ooRexx -> ICU4C, here ICU 78.3 / Unicode 17), registered
-- into the rxunicode package. UnicodeData.rex validates what utf8proc covers;
-- this test validates what ICU adds. Keeping them apart keeps each test's
-- back-end and guards honest.
--
-- ACCESS PATH - .RexxUnicode~codepointName, NOT .Unicode.ICU~Name:
-- The TUTOR facade .Unicode.ICU~Name calls .ICU4ooRexx~u_charName directly.
-- That external-library method is bound to the package context in which the
-- ICU library was first loaded, so it raises "does not understand" when this
-- test runs as a sub-program under the beta runner (Call "name_icu.rex" gives
-- it its own package context). .RexxUnicode~codepointName routes to the same
-- ICU back-end but through the globally-registered rxunicode layer, which IS
-- robust across package contexts. So we validate Name through codepointName.
-- (The facade's own context-fragility is a separate finding, noted in
-- decisions.md; revisiting it is future work.)
--
-- ORACLE: the official UnicodeData-17.0.0.txt, field 2. ICU here is U17, so
-- this is U17-vs-U17: a real standard oracle.
--
-- COVERAGE (option B, full algorithmic): every assigned codepoint with a name.
--   * Literal names: compared verbatim against field 2. Controls are special:
--     the UCD field 2 is literally "<control>", and codepointName returns ""
--     for them (the U_UNICODE_CHAR_NAME of a control is empty; the facade adds
--     a "<control-XXXX>" label via its own cascade, which codepointName does
--     not). Verified this session: all 65 Cc have codepointName "" and field 2
--     "<control>". We therefore expect "" from codepointName on every line
--     whose field 2 is "<control>".
--   * Algorithmic ranges (First>/Last>): the name is generated per the Unicode
--     rule, not read from the file. CJK Unified and Tangut ideographs follow
--     "<prefix>-<hex>"; Hangul syllables use gc.cls's independent generator
--     (a SEPARATE back-end from ICU, so the comparison is a genuine cross-check
--     rather than self-validation). Verified: 119331 algorithmic codepoints,
--     0 divergences.
--   * Surrogate (Cs) and Private-Use (Co) ranges are SKIPPED: no character name
--     in field 2.
--
-- GUARDS: requires the utf8proc binding at Unicode 17 (for the .Unicode classes
-- and the version pin), AND ICU must be registered. Without ICU, codepointName
-- would fall back to the U15 table and the U17 oracle would be wrong, so we
-- SKIP cleanly (Exit 0). .RexxUnicode~ICU4ooRexxIsRegistered is the guard, and
-- it too is robust across package contexts.

  Call "Unicode.cls"

  If \ .RexxUnicodeServices~isA(.Class) Then Do
    Say "name_icu.rex: no utf8proc binding present; skipping."
    Exit 0
  End

  expectedUnicode = "17.0.0"
  haveUnicode     = .RexxUnicodeServices~unicodeVersion
  If haveUnicode \== expectedUnicode Then Do
    Say "name_icu.rex: binding is Unicode '"haveUnicode"', oracle is"
    Say expectedUnicode". Refusing to run to avoid spurious version-divergences."
    Exit 1
  End

  -- Bring up the ICU layer; without it Name falls back to the U15 table and
  -- this oracle would be invalid. Skip cleanly if ICU is not present.
  callOK = .Unicode.ICU~LoadICULayer
  If \ ICURegistered() Then Do
    Say "name_icu.rex: ICU layer not registered; Name would fall back to the"
    Say "U15 table and the U17 oracle would be wrong. Skipping."
    Exit 0
  End

  -- The ICU wrapper and the embedded utf8proc binding ship together in this
  -- executor (ICU 78.3 / Unicode 17), so the U17 pin enforced above on the
  -- binding also pins ICU's Unicode version. If they were ever decoupled, the
  -- literal-name checks below would surface the difference as ordinary FAILs.

  gc = .Unicode.General_Category

  -- Oracle lives alongside this test (tests/beta/), resolved relative to it.
  oracleDir = .File~new(.context~package~name)~parent
  oracle    = oracleDir || .File~separator || "UnicodeData-"expectedUnicode".txt"

  Call Time "R"
  Say "Validating the Name property (served by the ICU layer, Unicode 17,"
  Say "via .RexxUnicode~codepointName) against the official"
  Say "UnicodeData-"expectedUnicode".txt (field 2: literal names verbatim,"
  Say "algorithmic ranges by rule)..."
  Say

  count   = 0
  inRange = .False

  Loop line Over .File~readLines(oracle)

    fields = line~makeArray(";")
    code   = fields[1]
    name   = fields[2]

    If inRange Then Do
      Call CheckRange rangeStart, X2D(code), rangeFamily
      inRange = .False
      Iterate
    End

    If name~caselessPos("First>") > 0 Then Do
      inRange     = .True
      rangeStart  = X2D(code)
      rangeFamily = NameFamily(name)
      Iterate
    End

    count += 1
    got = .RexxUnicode~codepointName( X2D(code) )

    If name == "<control>" Then exp = ""
    Else                        exp = name

    If got \== exp Then Do
      Say "FAIL: Name for U+"code": codepointName '"got"', UCD '"name"'."
      Exit 1
    End

  End

  Say "Inspected" count "codepoints, T=" Time("E")

  Exit 0

NameFamily: Procedure
  Use Arg label
  If label~caselessPos("CJK Ideograph")     > 0 Then Return "CJKU"
  If label~caselessPos("Tangut Ideograph")  > 0 Then Return "TANG"
  If label~caselessPos("Hangul Syllable")   > 0 Then Return "HANG"
  Return "NONE"

CheckRange: Procedure Expose gc count
  Use Arg lo, hi, family

  If family == "NONE" Then Return

  Do n = lo To hi
    code = D2X(n)
    count += 1
    got = .RexxUnicode~codepointName(n)
    Select
      When family == "CJKU" Then exp = "CJK UNIFIED IDEOGRAPH-"code
      When family == "TANG" Then exp = "TANGUT IDEOGRAPH-"code
      When family == "HANG" Then exp = gc~Algorithmic_Name(code)
    End
    If got \== exp Then Do
      Say "FAIL (algorithmic "family"): Name for U+"code":"
      Say "  codepointName '"got"', expected '"exp"'."
      Exit 1
    End
  End
  Return

ICURegistered: Procedure
  Signal On Syntax Name notReg
  Return .RexxUnicode~ICU4ooRexxIsRegistered
notReg:
  Return 0
