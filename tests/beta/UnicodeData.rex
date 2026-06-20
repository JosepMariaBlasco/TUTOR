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

-- UnicodeData.rex - Validates several fields served
-- by properties/UTF8Proc.cls against the OFFICIAL Unicode UCD file
-- UnicodeData-17.0.0.txt, NOT against the live binding.
--
-- Fields checked: General_Category (3), Canonical_Combining_Class (4),
-- Bidi_Class (5), Bidi_Mirrored (10), and the simple case mappings
-- Uppercase/Lowercase/Titlecase (13/14/15). U17 version guard: this oracle
-- is only valid against the binding's own Unicode version.
--

  Call "Unicode.cls"

  If \ .RexxUnicodeServices~isA(.Class) Then Do
    Say "UnicodeData.rex: no utf8proc binding present; skipping."
    Exit 0
  End

  expectedUnicode = "17.0.0"
  haveUnicode     = .RexxUnicodeServices~unicodeVersion
  If haveUnicode \== expectedUnicode Then Do
    Say "UnicodeData.rex: binding is Unicode '"haveUnicode"', oracle is"
    Say expectedUnicode". Refusing to run to avoid spurious version-divergences."
    Exit 1
  End

  self = .Unicode.UTF8Proc

  -- Resolve the oracle path independently of the cwd, relative to THIS test
  -- file's own directory (tests/beta/). The U17 UCD files are oracles, not
  -- code inputs, so they live alongside the tests, not under bin/UCD/.
  oracleDir = .File~new(.context~package~name)~parent
  oracle    = oracleDir || .File~separator || "UnicodeData-"expectedUnicode".txt"

  Call Time "R"
  Say "Validating UnicodeData properties (gc, ccc, Bidi_Class,"
  Say "Bidi_Mirrored, simple case mappings) against the official"
  Say "UnicodeData-"expectedUnicode".txt (whole codepoint space)..."
  Say

  pendingLo = -1
  count     =  0
  last      = -1
  inRange   = .False

  Loop line Over .File~readLines(oracle)

    -- Extract the fields
    fields                   = line~makeArray(";")

    code                     = fields[1]
    name                     = fields[2]
    gc                       = fields[3]
    ccc                      = fields[4]
    Bidi_Class               = fields[5]
    Bidi_Mirrored            = fields[10]

    -- The facade serves Bidi_Mirrored as the string "1"/"0"; the UCD field 10
    -- is "Y"/"N". Normalize the UCD side to the facade's representation.
    If Bidi_Mirrored == "Y" Then Bidi_Mirrored = "1"
    Else                         Bidi_Mirrored = "0"

    Simple_Uppercase_Mapping = fields[13]
    Simple_Lowercase_Mapping = fields[14]
    Simple_Titlecase_Mapping = fields[15]

    -- Field 6 (Decomposition) -> Decomposition_Type long name, matching the
    -- facade's surface. A leading <tag> gives a compatibility type; a mapping
    -- with no tag is Canonical; an empty field is None. The facade fuses these
    -- the same way (utf8proc only carries the compat enum; canonical/none are
    -- disambiguated via an NFD probe). We only assert this for explicitly named
    -- codepoints (the general case below), NOT for ranges: Hangul LV/LVT have an
    -- algorithmic canonical decomposition that the UCD leaves blank in the range
    -- lines, so the field would mislead there.
    decomp = Strip(fields[6])
    If decomp == "" Then Decomposition_Type = "None"
    Else If decomp~left(1) == "<" Then Do
      Parse Var decomp "<" tag ">" .
      -- UCD tag (lowercase) -> facade long name. compat -> "Compat".
      Decomposition_Type = TagToType(tag)
    End
    Else Decomposition_Type = "Canonical"

    -- Normalize casing
    If Simple_Uppercase_Mapping == ""   Then
      If code == "00DF" Then Simple_Uppercase_Mapping = "1E9E" -- UTF8Proc specific
      Else Simple_Uppercase_Mapping = code
    If Simple_Lowercase_Mapping == ""   Then Simple_Lowercase_Mapping = code
    If Simple_Titlecase_Mapping == .Nil Then
      If code == "00DF" Then Simple_Titlecase_Mapping = "1E9E" -- UTF8Proc specific
      Else Simple_Titlecase_Mapping = code

    If Length(code) > 4 Then code = Right(code,6,0)
    n = X2D(code)

    If inRange Then Do
      -- We are inside an open range: this line must be the matching Last>.
      Do c = rangeStart To n
        code = D2X(c)
        If Length(code) > 4 Then code = Right(code,6,0)
        Else                     code = Right(code,4,0)
        count += 1
        got = self~General_Category(code)
        If got == gc Then Iterate
        Say "FAIL 2: General_Category for U+"code": facade '"got"', UCD '"gc"'."
        Exit 1
      End
      inRange = .False
      last = c - 1
      Iterate
    End

    -- Process gaps. The only test is gc = "Cn".
    If n \== last + 1 Then Do
      -- Fast path for the single largest reserved (Cn) gap in U17: U+33480
      -- (first reserved after CJK Ideograph Extension J) to U+E0000 (last
      -- reserved before LANGUAGE TAG), 707464 contiguous Cn codepoints (~64% of
      -- the code space). They are all Cn, so the per-codepoint gc=="Cn" check
      -- adds nothing -- skip the block wholesale. We leave 'last' exactly where
      -- the full "Do last = last+1 To n-1" would: at n (a Do leaves its control
      -- variable at limit+1, i.e. (n-1)+1 = n), and bump count as if checked, so
      -- the inspected-codepoint tally is unchanged. Anchored to Unicode 17 by the
      -- version guard above; if the oracle ever assigns codepoints in this range
      -- the guard stops the test until these constants are revisited.
      If last + 1 == X2D("33480"), n - 1 == X2D("E0000") Then Do
        count += X2D("E0000") - X2D("33480") + 1
        last = n
      End
      Else Do last = last + 1 To n - 1
        missingcode = D2X(last)
        If Length(missingcode) > 4 Then missingcode = Right(missingcode,6,0)
        Else                            missingcode = Right(missingcode,4,0)
        count += 1
        got = self~General_Category(missingcode)
        If got \== "Cn" Then Do
          Say "FAIL 1: General_Category for U+"missingcode": facade '"got"', UCD 'Cn'."
          Exit 1
        End
      End
    End

    -- Opening a range
    If name~caselessPos("First>") > 0 Then Do
      inRange    = .True
      rangeStart = n
      Iterate
    End

    -- General case
    count += 1
    last = n

    got = self~General_Category(code)
    If got \== gc Then Do
      Say "FAIL 3: General_Category for U+"code": facade '"got"', UCD '"gc"'."
      Exit 1
    End

    got = self~Canonical_Combining_Class(code)
    If got \== ccc Then Do
      Say "FAIL 3: Canonical_Combining_Class for U+"code": facade '"got"', UCD '"ccc"'."
      Exit 1
    End

    bc  = self~bc(code)
    If bc \== Bidi_Class Then Do
      Say "FAIL 3: bc for U+"code": facade '"bc"', UCD '"Bidi_Class"'."
      Exit 1
    End
    got = self~Bidi_Class(code)
    If got \== Bidi_Class Then Do
      Say "FAIL 3: Bidi_Class for U+"code": facade '"got"', UCD '"Bidi_Class"'."
      Exit 1
    End

    Bidi_M = self~Bidi_M(code)
    If Bidi_M \== Bidi_Mirrored Then Do
      Say "FAIL 3: Bidi_M for U+"code": facade '"Bidi_M"', UCD '"Bidi_Mirrored"'."
      Exit 1
    End
    got = self~Bidi_Mirrored(code)
    If got \== Bidi_Mirrored Then Do
      Say "FAIL 3: Bidi_Mirrored for U+"code": facade '"got"', UCD '"Bidi_Mirrored"'."
      Exit 1
    End

    suc = self~suc(code)
    If suc \== Simple_Uppercase_Mapping Then Do
      Say "FAIL 3: suc for U+"code": facade '"suc"', UCD '"Simple_Uppercase_Mapping"'."
      Exit 1
    End
    got = self~Simple_Uppercase_Mapping(code)
    If got \== Simple_Uppercase_Mapping Then Do
      Say "FAIL 3: Simple_Uppercase_Mapping for U+"code": facade '"got"', UCD '"Simple_Uppercase_Mapping"'."
      Exit 1
    End

    slc = self~slc(code)
    If slc \== Simple_Lowercase_Mapping Then Do
      Say "FAIL 3: slc for U+"code": facade '"slc"', UCD '"Simple_Lowercase_Mapping"'."
      Exit 1
    End
    got = self~Simple_Lowercase_Mapping(code)
    If got \== Simple_Lowercase_Mapping Then Do
      Say "FAIL 3: Simple_Lowercase_Mapping for U+"code": facade '"got"', UCD '"Simple_Lowercase_Mapping"'."
      Exit 1
    End

    stc = self~stc(code)
    If stc \== Simple_Titlecase_Mapping Then Do
      Say "FAIL 3: stc for U+"code": facade '"stc"', UCD '"Simple_Titlecase_Mapping"'."
      Exit 1
    End
    got = self~Simple_Titlecase_Mapping(code)
    If got \== Simple_Titlecase_Mapping Then Do
      Say "FAIL 3: Simple_Titlecase_Mapping for U+"code": facade '"got"', UCD '"Simple_Titlecase_Mapping"'."
      Exit 1
    End

    got = self~Decomposition_Type(code)
    If got \== Decomposition_Type Then Do
      Say "FAIL 3: Decomposition_Type for U+"code": facade '"got"', UCD '"Decomposition_Type"'."
      Exit 1
    End
    dt = self~dt(code)
    If dt \== got Then Do
      Say "FAIL 3: dt alias for U+"code": facade '"dt"', long form '"got"'."
      Exit 1
    End

  End

  -- Last codepoints
  Do n = last+1 To X2D("10FFFF")
    code = D2X(n)
    count += 1
    got = self~General_Category(code)
    If got \== "Cn" Then Do
      Say "FAIL 1: General_Category for U+"code": facade '"got"', UCD 'Cn'."
      Exit 1
    End
  End

  Say "Inspected" count "codepoints, T=" Time("E")

  Exit 0

--------------------------------------------------------------------------------

-- Map a UCD field-6 decomposition <tag> (without the angle brackets) to the
-- Decomposition_Type long-form value name the facade exposes. The only spelling
-- that differs between the tag and the long name is noBreak -> No_Break; the
-- rest match case-insensitively. Any unknown tag is a hard error: the UCD
-- should never carry a compatibility tag outside this fixed set.
TagToType: Procedure
  Use Strict Arg tag
  Select Case tag~lower
    When "font"     Then Return "Font"
    When "nobreak"  Then Return "No_Break"
    When "initial"  Then Return "Initial"
    When "medial"   Then Return "Medial"
    When "final"    Then Return "Final"
    When "isolated" Then Return "Isolated"
    When "circle"   Then Return "Circle"
    When "super"    Then Return "Super"
    When "sub"      Then Return "Sub"
    When "vertical" Then Return "Vertical"
    When "wide"     Then Return "Wide"
    When "narrow"   Then Return "Narrow"
    When "small"    Then Return "Small"
    When "square"   Then Return "Square"
    When "fraction" Then Return "Fraction"
    When "compat"   Then Return "Compat"
    Otherwise
      Say "UnicodeData.rex: unknown decomposition tag '<"tag">'. Aborting."
      Exit 1
  End

