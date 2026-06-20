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

-- tocasefold.rex - Validates the toCasefold function served by
-- properties/UTF8Proc.cls against the OFFICIAL Unicode file
-- CaseFolding-17.0.0.txt. toCasefold is Unicode Default Case Folding (ch.
-- 3.13, full folding), delegating to utf8Transform(string, casefold=.true).
--
-- ORACLE / SUBJECT: the oracle is CaseFolding-17.0.0.txt; the subject under
-- test is utf8proc (the Unicode 17 binding inside librexx, via the toCasefold
-- facade). This is U17-vs-U17 -- a real standard oracle, NOT facade-vs-binding.
--
-- WHY THIS IS A CLASS (b) ORACLE. utf8proc's toCasefold performs Unicode FULL
-- case folding. The standard defines full folding as the mappings with status
-- C (common) + F (full); see the Usage note in CaseFolding.txt. So the
-- reference for each codepoint is built straight from the official file:
--   * status C -> single-codepoint common mapping;
--   * status F -> multi-codepoint full mapping (the ones that GROW, e.g.
--     00DF SHARP S -> 0073 0073 "ss"); up to three codepoints (Greek
--     polytonic, FFI/FFL ligatures);
--   * status S (simple) is IGNORED -- it is the alternative single-codepoint
--     fold used only for simple folding, not full;
--   * status T (Turkic, only 0049 and 0130) is IGNORED -- the default,
--     non-Turkic behaviour, which is what utf8proc implements.
-- A codepoint not listed folds to itself. The mapping is ONE STEP: unlike
-- canonical decomposition, full folding needs no recursion and no canonical
-- ordering (the F sequences are already in final folded form).
--
-- This SUPERSEDES the previous facade-vs-binding consistency check: that one
-- could only assert "the facade reproduces the binding", never "the binding
-- matches the standard". The class-preservation contract below is NOT a
-- Unicode property and has no UCD oracle, so it stays as a facade check.
--
-- COVERAGE: the BMP is always swept per-codepoint. The astral plane is swept
-- in full only when the test is called with argument "full" or "1"; otherwise
-- a curated sample of cased astral codepoints is probed (default, fast -- this
-- is how the runner calls it). Verified this session in full mode: 1112064
-- codepoints checked, 0 divergences between utf8proc toCasefold and the
-- CaseFolding.txt reconstruction (C+F, S and T excluded).
--
-- GUARD: requires the utf8proc binding at Unicode 17 (the oracle's version).
-- No ICU dependency (toCasefold and the .Unicode classes used here are served
-- by utf8proc / tables that are robust across package contexts).

  Call "Unicode.cls"

  If \ .RexxUnicodeServices~isA(.Class) Then Do
    Say "tocasefold.rex: no utf8proc binding present; skipping."
    Exit 0
  End

  expectedUnicode = "17.0.0"
  haveUnicode     = .RexxUnicodeServices~unicodeVersion
  If haveUnicode \== expectedUnicode Then Do
    Say "tocasefold.rex: binding is Unicode '"haveUnicode"', oracle is"
    Say expectedUnicode". Refusing to run to avoid spurious version-divergences."
    Exit 1
  End

  -- Optional argument selects the astral coverage. Default (no argument, as the
  -- runner calls it) is a curated astral SAMPLE -- fast, enough for the suite.
  -- Pass "full" or "1" for the exhaustive astral sweep (10000..10FFFF), a deep
  -- manual check. The BMP is ALWAYS swept exhaustively either way. Parse Arg
  -- (not Arg(1)) is used so an omitted argument under Call yields "" cleanly.
  Parse Arg rawArg
  mode     = Lower( Strip(rawArg) )
  fullSweep = ( mode == "1" | mode == "full" )

  u8 = .Unicode.UTF8Proc
  -- Oracle lives alongside this test (tests/beta/), resolved relative to it.
  oracleDir = .File~new(.context~package~name)~parent
  oracle    = oracleDir || .File~separator || "CaseFolding-"expectedUnicode".txt"

  -- Build the full-fold reference from the UCD: status C + F only. S is the
  -- simple-fold alternative (excluded from full); T is Turkic (excluded by
  -- default). A codepoint absent from the map folds to itself.
  fold. = ""
  cLoaded = 0; fLoaded = 0
  Do line Over .File~readLines(oracle)
    If line == "" Then Iterate
    If line~left(1) == "#" Then Iterate
    p  = line~makeArray(";")
    cp = p[1]~strip
    st = p[2]~strip
    mp = p[3]~strip
    Select
      When st == "C" Then Do; fold.cp = mp; cLoaded += 1; End
      When st == "F" Then Do; fold.cp = mp; fLoaded += 1; End
      Otherwise Nop   -- S and T deliberately ignored.
    End
  End

  If cLoaded == 0 | fLoaded == 0 Then Do
    Say "tocasefold.rex: oracle load failed (C="cLoaded" F="fLoaded") -- aborting."
    Exit 1
  End

  Call Time "R"
  Say "Validating utf8proc full case folding (toCasefold) against the official"
  Say "CaseFolding-"expectedUnicode".txt (status C + F)..."
  Say "Loaded" cLoaded "common +" fLoaded "full mappings (S, T excluded)."
  Say

  -- 1. Canonical sanity cases (human-readable).
  cases.1 = "Straße"  ; expect.1 = "strasse"
  cases.2 = "STRASSE" ; expect.2 = "strasse"
  cases.3 = "Hello"   ; expect.3 = "hello"
  cases.4 = "İ"       ; expect.4 = "i̇"      -- U+0130 -> i + combining dot above
  cases.0 = 4
  Do c = 1 To cases.0
    got = Unicode(cases.c, "toCasefold")
    If got \== expect.c Then Do
      Say "Sanity case" c": toCasefold('"cases.c"') = '"got"', expected '"expect.c"'."
      Exit 1
    End
  End
  Say "Sanity cases: 4 OK."

  -- 2. Per-codepoint sweep: utf8proc toCasefold must equal the CaseFolding.txt
  --    reconstruction. The BMP is always swept in full. The astral plane is
  --    either swept in full (fullSweep) or probed via a curated sample of
  --    cased astral codepoints (Deseret, Osage, Adlam, Warang Citi, Medefaidrin,
  --    Old Hungarian) plus a few non-cased controls/emoji that must fold to
  --    themselves.
  count = 0

  -- BMP: always exhaustive.
  Do i = 0 To X2D("FFFF")
    If i >= X2D("D800"), i <= X2D("DFFF") Then Iterate   -- surrogates
    If \ CheckCP(i, fold., u8) Then Exit 1
    count += 1
  End

  If fullSweep Then Do
    Say "Astral: full sweep (10000..10FFFF)."
    Do i = X2D("10000") To X2D("10FFFF")
      If \ CheckCP(i, fold., u8) Then Exit 1
      count += 1
    End
  End
  Else Do
    Say "Astral: curated sample (pass 'full' or '1' for the exhaustive sweep)."
    -- Cased astral letters (have a fold) + non-cased (must fold to self).
    astral = "10400 10428 104B0 104D8 10C80 10CC0 118A0 118C0 16E40 16E60" -
             "1E900 1E922 10000 1F600 2F800 E0001 10FFFF"
    Do code Over astral~makeArray(" ")
      If \ CheckCP(X2D(code), fold., u8) Then Exit 1
      count += 1
    End
  End

  -- Guard against a false green.
  If count == 0 Then Do
    Say "tocasefold.rex: 0 codepoints checked -- aborting as a false green."
    Exit 1
  End

  -- 3. Class-preservation contract (NOT a Unicode property: facade behaviour).
  --    A String stays a String; .Codepoints stays a .Codepoints.
  s = Unicode("Test", "toCasefold")
  If \ s~isA(.String) Then Do
    Say "Class contract: String input did not yield a String."
    Exit 1
  End
  cp = Unicode( Codepoints("Test"), "toCasefold")
  If \ cp~isA(.Codepoints) Then Do
    Say "Class contract: .Codepoints input did not yield a .Codepoints."
    Exit 1
  End
  Say "Class-preservation contract: OK."

  Say "Checked" count "codepoints, 0 failures."
  Say "Elapsed:" Time("E")"s."

Exit 0

--------------------------------------------------------------------------------

-- Compare utf8proc's toCasefold of one codepoint against the UCD-derived full
-- fold (status C + F, or identity if unlisted).
CheckCP: Procedure
  Use Strict Arg n, fold., u8

  cp = D2X(n)
  If Length(cp) < 4 Then cp = Right(cp, 4, 0)

  If fold.cp == "" Then ref = cp
  Else                  ref = NiceList(fold.cp)

  txt = .Codepoints~new(cp)~U2C
  got = NiceList( .Bytes~new( u8~toCasefold(txt) )~C2U )

  If ref == got Then Return 1

  Say "FAIL: toCasefold of U+"cp":"
  Say "  utf8proc '"got"', CaseFolding.txt '"ref"'."
  Return 0

-- Normalize a blank-separated list of hex codepoints (strip leading zeros,
-- min width 4), matching the C2U output format.
NiceList: Procedure
  Use Arg s
  out = ""
  Do w Over s~makeArray(" ")
    w = w~strip
    w = Strip(w, "L", "0")
    If Length(w) < 4 Then w = Right(w, 4, "0")
    out = out w
  End
  Return Strip(out)
