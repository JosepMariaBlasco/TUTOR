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

-- derived_properties.rex - Validates the facade's boolean predicates that are
-- DERIVED CORE PROPERTIES of the UCD (served by properties/UTF8Proc.cls over the
-- utf8proc binding) against the OFFICIAL Unicode file
-- DerivedCoreProperties-17.0.0.txt:
--
--   Uppercase                    (Uppercase / Upper   <- codepointIsUpper)
--   Lowercase                    (Lowercase / Lower   <- codepointIsLower)
--   Default_Ignorable_Code_Point (DI                  <- codepointIgnorable)
--
-- WHY THESE ARE REAL UCD ORACLES (class b, not class a). None of these is a
-- General_Category test; they are derived properties with their own inclusion/
-- exclusion rules, and utf8proc stores the derived bits in its property table:
--   * Uppercase = Lu + Other_Uppercase, Lowercase = Ll + Other_Lowercase, so
--     U+2160 (ROMAN NUMERAL ONE, gc=Nl) and U+24B6 (CIRCLED LATIN CAPITAL A,
--     gc=So) are Uppercase=Y though not Lu. A gc-based synthetic would be wrong.
--   * Default_Ignorable_Code_Point is a formula (Other_Default_Ignorable + Cf +
--     variation selectors, minus White_Space, minus a few specific ranges), not
--     any single column. The UCD ships the resolved result, which is the oracle.
--
-- ORACLE: DerivedCoreProperties-17.0.0.txt. Each property section lists only the
-- codepoints that HAVE the property (single points or XXXX..YYYY ranges);
-- everything not listed is N. We build one set per property, then sweep the
-- whole codepoint space asserting the facade returns 1 exactly on the set.
--
-- KNOWN DIVERGENCE on RESERVED code points (Default_Ignorable_Code_Point only).
-- The UCD declares whole Cn (unassigned) ranges as Default_Ignorable ahead of
-- time -- <reserved-2065>, FFF0..FFF8, E0080..E00FF, E01F0..E0FFF, ... -- so the
-- standard reports DI=1 there. utf8proc computes properties only over ASSIGNED
-- code points and returns DI=0 for unassigned ones. This is a difference of
-- SCOPE (the standard pre-declares the reserved space; utf8proc does not), not a
-- facade bug: the facade faithfully reproduces utf8proc. We therefore assert DI
-- only where the code point is assigned (gc \== Cn) and skip the reserved space,
-- where the two sides legitimately disagree. Uppercase/Lowercase are unaffected
-- (they never include reserved code points).
--
-- The oracle is U17, so the test carries a version guard: it refuses to run on
-- any other binding version to avoid spurious version-divergences.

  Call "Unicode.cls"

  If \ .RexxUnicodeServices~isA(.Class) Then Do
    Say "derived_properties.rex: no utf8proc binding present; skipping."
    Exit 0
  End

  expectedUnicode = "17.0.0"
  haveUnicode     = .RexxUnicodeServices~unicodeVersion
  If haveUnicode \== expectedUnicode Then Do
    Say "derived_properties.rex: binding is Unicode '"haveUnicode"', oracle is"
    Say expectedUnicode". Refusing to run to avoid spurious version-divergences."
    Exit 1
  End

  self = .Unicode.UTF8Proc

  -- Oracle lives alongside this test (tests/beta/), resolved relative to it.
  oracleDir = .File~new(.context~package~name)~parent
  oracle    = oracleDir || .File~separator || "DerivedCoreProperties-"expectedUnicode".txt"

  Call Stream oracle, "c", "query exists"
  If result == "" Then Do
    Say "derived_properties.rex: oracle '"oracle"' not found. Aborting."
    Exit 1
  End

  Call Time "R"
  Say "Validating Uppercase / Lowercase / Default_Ignorable_Code_Point (derived"
  Say "core properties) against the official DerivedCoreProperties-"expectedUnicode".txt"
  Say "(whole codepoint space, skipping central gap)..."
  Say

  -- Load one membership set per property. Entries default to 0 (off).
  isUpper. = 0
  isLower. = 0
  isDI.    = 0
  loaded   = 0

  Do While Lines(oracle) > 0
    line = LineIn(oracle)
    -- Strip comments and skip blank lines.
    Parse Var line line "#" .
    line = Strip(line)
    If line == "" Then Iterate
    Parse Var line range ";" prop .
    range = Strip(range)
    prop  = Strip(prop)
    Select Case prop
      When "Uppercase", "Lowercase", "Default_Ignorable_Code_Point" Then Nop
      Otherwise Iterate
    End
    -- range is either "XXXX" or "XXXX..YYYY".
    Parse Var range lo ".." hi
    lo = X2D(Strip(lo))
    If hi == "" Then hi = lo
    Else            hi = X2D(Strip(hi))
    Do cp = lo To hi
      Select Case prop
        When "Uppercase"                    Then isUpper.cp = 1
        When "Lowercase"                    Then isLower.cp = 1
        When "Default_Ignorable_Code_Point" Then isDI.cp    = 1
      End
      loaded += 1
    End
  End
  Call Stream oracle, "c", "close"

  -- Guard against a false green from an empty/garbled oracle.
  If loaded == 0 Then Do
    Say "derived_properties.rex: 0 property entries loaded from oracle -- aborting."
    Exit 1
  End

  -- Sweep the whole codepoint space, skipping the surrogate range (no chars)
  -- and the single largest reserved (Cn) gap. In U17 that gap runs from U+33480
  -- (first reserved after CJK Ideograph Extension J) to U+E0000 (last reserved
  -- before LANGUAGE TAG): 707464 contiguous Cn codepoints, ~64% of the code
  -- space. They are all Cn, so Uppercase/Lowercase are 0 and DI is skipped
  -- throughout -- nothing to assert -- and jumping the block wholesale keeps the
  -- sweep exhaustive over everything assignable while cutting most of the cost.
  -- The bounds are anchored to Unicode 17 by the version guard above; if the
  -- oracle ever moves to a version that assigns codepoints in this range, the
  -- guard stops the test until these constants are revisited.
  gapLo = X2D("33480")   -- first Cn after CJK Ideograph Extension J
  gapHi = X2D("E0000")   -- last Cn before LANGUAGE TAG (U+E0001)

  count = 0
  Do n = 0 To X2D("10FFFF")

    If n == gapLo Then Do
      n = gapHi          -- jump the whole Cn gap (loop's += 1 moves to gapHi+1)
      Iterate
    End

    code = D2X(n)
    If Length(code) > 4 Then code = Right(code, 6, 0)
    Else                     code = Right(code, 4, 0)

    got = self~Uppercase(code)
    exp = isUpper.n
    If got \== exp Then Do
      Say "FAIL: Uppercase for U+"code": facade '"got"', UCD '"exp"'."
      Exit 1
    End

    got = self~Lowercase(code)
    exp = isLower.n
    If got \== exp Then Do
      Say "FAIL: Lowercase for U+"code": facade '"got"', UCD '"exp"'."
      Exit 1
    End

    got = self~Default_Ignorable_Code_Point(code)
    DI  = self~DI(code)
    exp = isDI.n
    -- Assert only on assigned code points; reserved Cn ranges are a known
    -- scope divergence (see header). gc == Cn => skip.
    If self~General_Category(code) \== "Cn" Then Do
      If DI \== exp Then Do
        Say "FAIL: DI for U+"code": facade '"DI"', UCD '"exp"'."
        Exit 1
      End
      If got \== exp Then Do
        Say "FAIL: Default_Ignorable_Code_Point for U+"code": facade '"got"', UCD '"exp"'."
        Exit 1
      End
    End

    count += 1
  End

  Say "Inspected" count "codepoints, T=" Time("E")

Exit 0
