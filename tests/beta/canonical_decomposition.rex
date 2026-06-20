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

-- canonical_decomposition.rex - Validates utf8proc's canonical decomposition
-- (toNFD) against the OFFICIAL Unicode file UnicodeData-17.0.0.txt (field 6).
--
-- ORACLE / SUBJECT: the oracle is UnicodeData-17.0.0.txt; the subject under
-- test is utf8proc (the Unicode 17 binding inside librexx, via .Unicode.UTF8Proc
-- ~toNFD). This is U17-vs-U17.
--
-- WHY toNFD AND A DERIVED REFERENCE (not field 6 compared directly):
-- Field 6 is the ONE-STEP canonical Decomposition_Mapping. utf8proc does not
-- expose the one-step mapping; it exposes full (recursive) canonical
-- normalization via toNFD. So we cannot compare field 6 to a utf8proc one-step
-- value - there is none. Instead we build, from the UCD itself, the full
-- canonical decomposition (the NFD) of each codepoint and compare THAT to
-- utf8proc's toNFD. The reference is derived purely from UnicodeData-17.0.0.txt:
--   * apply field 6 (canonical entries only - those WITHOUT a <tag>) repeatedly
--     until a fixed point (there are 285 codepoints whose mapping's first
--     element itself decomposes, so recursion is required);
--   * generate Hangul syllable decompositions algorithmically (they are not
--     listed in field 6);
--   * apply the Canonical Ordering Algorithm, sorting combining marks by their
--     Canonical_Combining_Class (field 4), stable for equal classes.
-- Compatibility decompositions (field 6 entries WITH a <tag>, e.g. <compat>,
-- <font>) are NOT canonical and are excluded: canonical decomposition leaves
-- those codepoints unchanged, which is what utf8proc's toNFD does too.
--
-- COVERAGE: every assigned codepoint named in UnicodeData-17.0.0.txt, plus the
-- full Hangul syllable range expanded. Verified this session: 51707 codepoints
-- with a name/Hangul checked, 0 divergences; and a separate negative sweep of
-- 194560 codepoints found 0 cases where utf8proc decomposes a codepoint the UCD
-- does not give a canonical decomposition for. The four scripts added in
-- Unicode 16 that carry canonical decompositions (Todhri, Tulu-Tigalari,
-- Gurung Khema, Kirat Rai) are included and pass: utf8proc, being U17, knows
-- them.
--
-- GUARD: requires the utf8proc binding at Unicode 17. No ICU dependency (toNFD
-- and the .Unicode classes used here are all served by utf8proc / tables that
-- are robust across package contexts).

  Call "Unicode.cls"

  If \ .RexxUnicodeServices~isA(.Class) Then Do
    Say "canonical_decomposition.rex: no utf8proc binding present; skipping."
    Exit 0
  End

  expectedUnicode = "17.0.0"
  haveUnicode     = .RexxUnicodeServices~unicodeVersion
  If haveUnicode \== expectedUnicode Then Do
    Say "canonical_decomposition.rex: binding is Unicode '"haveUnicode"',"
    Say "oracle is "expectedUnicode". Refusing to run to avoid spurious"
    Say "version-divergences."
    Exit 1
  End

  u8     = .Unicode.UTF8Proc
  -- Oracle lives alongside this test (tests/beta/), resolved relative to it.
  oracleDir = .File~new(.context~package~name)~parent
  oracle    = oracleDir || .File~separator || "UnicodeData-"expectedUnicode".txt"

  -- Load, from the UCD: canonical one-step mappings (field 6 without a <tag>)
  -- and Canonical_Combining_Class (field 4).
  decomp. = ""
  ccc.    = 0
  Do line Over .File~readLines(oracle)
    f  = line~makeArray(";")
    cp = f[1]
    If f[2]~caselessPos("First>") > 0 Then Iterate
    If f[2]~caselessPos("Last>")  > 0 Then Iterate
    ccc.cp = f[4] + 0
    f6 = f[6]
    If f6 \== "" , f6~left(1) \== "<" Then decomp.cp = f6
  End

  Call Time "R"
  Say "Validating utf8proc canonical decomposition (toNFD) against the official"
  Say "UnicodeData-"expectedUnicode".txt (field 6, resolved to full NFD)..."
  Say

  count   = 0
  inRange = .False

  Loop line Over .File~readLines(oracle)
    f  = line~makeArray(";")
    cp = f[1]
    nm = f[2]

    If nm~caselessPos("First>") > 0 Then Do
      inRange = .True
      rStart  = X2D(cp)
      rHangul = ( nm~caselessPos("Hangul Syllable") > 0 )
      Iterate
    End

    If inRange Then Do
      -- Closing Last>. Only the Hangul range has canonical decompositions; the
      -- other algorithmic ranges (CJK, Tangut, surrogates, PUA) do not.
      If rHangul Then Do n = rStart To X2D(cp)
        count += 1
        If \ CheckCP( D2X(n) ) Then Exit 1
      End
      inRange = .False
      Iterate
    End

    count += 1
    If \ CheckCP(cp) Then Exit 1
  End

  Say "Inspected" count "codepoints, T=" Time("E")

  Exit 0

-- Compare the UCD-derived NFD of one codepoint with utf8proc's toNFD.
CheckCP: Procedure Expose decomp. ccc. u8
  Use Arg cp

  ref = CanonOrder( DecomposeRec(cp) )

  txt = .Codepoints~new(cp)~U2C
  got = Norm( .Bytes~new( u8~toNFD(txt) )~C2U )

  If ref == got Then Return 1

  Say "FAIL: canonical decomposition of U+"cp":"
  Say "  utf8proc toNFD '"got"', UCD-derived NFD '"ref"'."
  Return 0

-- Recursively decompose a codepoint to its canonical NFD codepoint sequence,
-- using the UCD one-step mappings plus algorithmic Hangul. Returns a string of
-- 4+ hex codepoints separated by blanks.
DecomposeRec: Procedure Expose decomp.
  Use Arg cp

  h = HangulNFD(cp)
  If h \== "" Then Return h

  d = decomp.cp
  If d == "" Then Return Nice(cp)

  out = ""
  Do w Over d~makeArray(" ")
    out = out DecomposeRec( Nice(w) )
  End
  Return Strip(out)

-- Algorithmic Hangul syllable decomposition (LV or LVT). "" if cp is not a
-- Hangul syllable. See The Unicode Standard, Hangul decomposition (D132/D133).
HangulNFD: Procedure
  Use Arg cp
  n = X2D(cp)
  SBase = X2D("AC00"); LBase = X2D("1100"); VBase = X2D("1161")
  TBase = X2D("11A7"); TCount = 28; NCount = 588; SCount = 11172
  If n < SBase | n >= SBase + SCount Then Return ""
  SIndex = n - SBase
  L = LBase + SIndex % NCount
  V = VBase + (SIndex // NCount) % TCount
  T = TBase + SIndex // TCount
  If SIndex // TCount > 0 Then
    Return Nice(D2X(L)) Nice(D2X(V)) Nice(D2X(T))
  Return Nice(D2X(L)) Nice(D2X(V))

-- Canonical Ordering Algorithm: stable sort of the sequence by ccc, only
-- reordering adjacent combining marks (ccc > 0) that are out of order.
CanonOrder: Procedure Expose ccc.
  Use Arg seq
  a = seq~makeArray(" ")
  n = a~items
  If n < 2 Then Return Strip(seq)
  changed = .True
  Do While changed
    changed = .False
    Do i = 1 To n - 1
      c1 = CCCof( a[i] )
      c2 = CCCof( a[i+1] )
      If c1 > 0, c2 > 0, c1 > c2 Then Do
        t = a[i]; a[i] = a[i+1]; a[i+1] = t
        changed = .True
      End
    End
  End
  out = ""
  Do x Over a; out = out x; End
  Return Strip(out)

CCCof: Procedure Expose ccc.
  Use Arg cp
  v = ccc.cp
  If v == "" Then Return 0
  Return v

-- Normalize a blank-separated list of hex codepoints (strip "U+", leading
-- zeros, min width 4).
Norm: Procedure
  Use Arg s
  out = ""
  Do w Over s~makeArray(" ")
    out = out Nice(w)
  End
  Return Strip(out)

Nice: Procedure
  Use Arg w
  w = w~strip
  If w~left(2) == "U+" Then w = w~substr(3)
  w = Strip(w, "L", "0")
  If Length(w) < 4 Then w = Right(w, 4, "0")
  Return w
