/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/TUTOR/                                          *
 *     and https://github.com/JosepMariaBlasco/TUTOR                          *
 * Copyright © 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>    *
 * License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  *
 ******************************************************************************/

/*****************************************************************************/
/*                                                                           */
/*  The UNICODE.UTF8Proc plug-in                                             */
/*  ============================                                             */
/*                                                                           */
/*  OPTIONAL back-end. When this file is loaded, it registers itself as the  */
/*  PREFERRED handler (overriding the default .bin table classes) for the    */
/*  list of properties below, delegating to utf8proc binding                 */
/*  (.RexxUnicodeServices). If the file is NOT loaded, TUTOR works exactly   */
/*  as before, on the .bin tables.                                           */
/*                                                                           */
/*  This is the utf8proc layer. A sibling ICU4ooRexx plug-in covers the      */
/*  properties that utf8proc does not expose (e.g. Name).                    */
/*                                                                           */
/*  The registration list below IS the coverage inventory for this layer:    */
/*  the single source of truth for "what utf8proc takes over".               */
/*                                                                           */
/*    Uppercase / Upper          codepointIsUpper      (POC v6, verified)    */
/*    Lowercase / Lower          codepointIsLower      (POC v6, verified)    */
/*    Simple_Uppercase_Mapping   codepointToUpper      (v5, verified)        */
/*    Simple_Lowercase_Mapping   codepointToLower      (v5, verified)        */
/*    Simple_Titlecase_Mapping   codepointToTitle      (verified)            */
/*    Canonical_Combining_Class  codepointCombining-   (v9, verified)        */
/*    / ccc                      Class                                       */
/*    General_Category / gc      codepointCategory     (v9, verified)        */
/*    Bidi_Class / bc            codepointBidiClass    (verified)            */
/*    Bidi_Mirrored / Bidi_M     codepointBidiMirrored (verified)            */
/*    Default_Ignorable_-        codepointIgnorable    (verified)            */
/*    Code_Point / DI                                                        */
/*    utf8proc_Char_Width        codepointCharWidth    (verified)            */
/*    (utf8proc metric, NOT a UCD property)                                  */
/*    Decomposition_Type / dt    codepointDecompo-     (verified)            */
/*                               sitionType + NFD probe                      */
/*    utf8proc_Decomposition_-    codepointDecompo-     (verified)           */
/*    Type (raw enum 0..16)      sitionType                                  */
/*                                                                           */
/*  Functions (string -> string, not per-codepoint properties):              */
/*    toNFC toNFD toNFKC toNFKD   utf8Transform         (v10)                */
/*    The K forms have no table equivalent: utf8proc is their only provider. */
/*                                                                           */
/*  VERSION NOTE: U+0295 LATIN LETTER PHARYNGEAL VOICED FRICATIVE was Ll in   */
/*  the UCD up to U16 and became Lo in U17 (the single gc change between      */
/*  those releases). utf8proc serves U17 and reports Lo; we delegate to it    */
/*  unchanged. So gc(U+0295) is Lo on this binding (U17) but Ll on the U15    */
/*  table route -- a genuine version-divergence, exactly the kind of signal   */
/*  TUTOR exists to surface, not a bug to patch.                             */
/*                                                                           */
/*  NOTE on code normalization: every method replicates the                  */
/*    If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])       */
/*  guard used by the table classes, so a 4-byte 00-prefixed code is         */
/*  accepted exactly as the original facade expects.                         */
/*                                                                           */
/*  Version history                                                          */
/*  ===============                                                          */
/*                                                                           */
/*  Vers. Aut Date     Comments                                              */
/*  ----- --- -------- ----------------------------------------------------- */
/*   0.7  JMB 20260617 Initial plug-in: Upper/Lower/suc/slc over utf8proc    */
/*        JMB 20260617 Add Canonical_Combining_Class (ccc) over utf8proc     */
/*        JMB 20260617 Add General_Category (gc); U+0295 override (Ll)       */
/*        JMB 20260618 Remove U+0295 override: U17 UCD assigns it Lo, so      */
/*                     delegate to utf8proc unchanged (version-divergence,    */
/*                     not a bug). See VERSION NOTE above.                    */
/*        JMB 20260617 Add toNFC/toNFD/toNFKC/toNFKD over utf8Transform )    */
/*        JMB 20260617 Add Simple_Titlecase_Mapping (stc) over               */
/*                     codepointToTitle                                      */
/*        JMB 20260617 Add Bidi_Class (bc) and Bidi_Mirrored over utf8proc   */
/*        JMB 20260617 Add Default_Ignorable_Code_Point (DI) and             */
/*                     utf8proc_Char_Width                                   */
/*        JMB 20260617 Add toCasefold (Unicode Default Case Folding)         */
/*        JMB 20260617 Add Decomposition_Type (dt) [enum + NFD probe] and    */
/*                     utf8proc_Decomposition_Type (raw enum)                */
/*                                                                           */
/*****************************************************************************/

.local~Unicode.UTF8Proc = .Unicode.UTF8Proc

::Class Unicode.UTF8Proc Public SubClass Unicode.Property

::Method Activate Class

  -- The list below IS the coverage inventory for the utf8proc layer.
  -- Only properties verified against the oracle are registered.
  super~RegisterPreferredProperties( -
    "Uppercase Upper Lowercase Lower" -
    "Simple_Uppercase_Mapping suc Simple_Lowercase_Mapping slc" -
    "Simple_Titlecase_Mapping stc" -
    "Canonical_Combining_Class ccc" -
    "General_Category gc" -
    "Bidi_Class bc Bidi_Mirrored Bidi_M" -
    "Default_Ignorable_Code_Point DI utf8proc_Char_Width" -
    "Decomposition_Type dt utf8proc_Decomposition_Type" -
    "utf8proc_codepointBoundClass utf8proc_codepointControlBoundary" -
    , self )

  -- Normalization functions. utf8proc is the ONLY provider of the K forms
  -- (toNFKC/toNFKD); it also takes over toNFC/toNFD (the table class registers
  -- them first; we override here). All four delegate to utf8Transform, U17.
  super~RegisterPreferredFunctions( "toNFC toNFD toNFKC toNFKD toCasefold", self )

-------------------------------------------------------------------------------
-- Property methods. Facade identical to the table classes they replace:     --
-- same input handling, same return shape.                                   --
-------------------------------------------------------------------------------

::Method Upper     Class
  Forward Message "Uppercase"
::Method Uppercase Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  Return .RexxUnicodeServices~codepointIsUpper(X2D(code)) == 1

::Method Lower     Class
  Forward Message "Lowercase"
::Method Lowercase Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  Return .RexxUnicodeServices~codepointIsLower(X2D(code)) == 1

::Method suc                      Class
  Forward Message "Simple_Uppercase_Mapping"
::Method Simple_Uppercase_Mapping Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  n     = X2D(code)
  upper = D2X( .RexxUnicodeServices~codepointToUpper(n) )
  If Length(upper) < 4 Then Return Right(upper, 4, 0)
  Return upper

::Method slc                      Class
  Forward Message "Simple_Lowercase_Mapping"
::Method Simple_Lowercase_Mapping Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  n     = X2D(code)
  lower = D2X( .RexxUnicodeServices~codepointToLower(n) )
  If Length(lower) < 4 Then Return Right(lower, 4, 0)
  Return lower

::Method stc                      Class
  Forward Message "Simple_Titlecase_Mapping"
::Method Simple_Titlecase_Mapping Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  n     = X2D(code)
  title = D2X( .RexxUnicodeServices~codepointToTitle(n) )
  If Length(title) < 4 Then Return Right(title, 4, 0)
  Return title

::Method ccc                       Class
  Forward Message "Canonical_Combining_Class"
::Method Canonical_Combining_Class Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  Return .RexxUnicodeServices~codepointCombiningClass(X2D(code))

::Method gc               Class
  Forward Message "General_Category"
::Method General_Category Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  n = X2D(code)
  .RexxUnicodeServices~codepointCategory(n, >label)
  Return label

::Method bc         Class
  Forward Message "Bidi_Class"
::Method Bidi_Class Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  .RexxUnicodeServices~codepointBidiClass(X2D(code), >shortCode, >label)
  Return shortCode

::Method Bidi_M        Class
  Forward Message "Bidi_Mirrored"
::Method Bidi_Mirrored Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  Return .RexxUnicodeServices~codepointBidiMirrored(X2D(code)) == 1

::Method DI                           Class
  Forward Message "Default_Ignorable_Code_Point"
::Method Default_Ignorable_Code_Point Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  Return .RexxUnicodeServices~codepointIgnorable(X2D(code)) == 1

::Method utf8proc_Char_Width Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  Return .RexxUnicodeServices~codepointCharWidth(X2D(code))

-- utf8proc_Decomposition_Type: the RAW utf8proc enum (integer 0..16), NOT the
-- UCD property. utf8proc_ prefix on purpose (twin of utf8proc_Char_Width):
-- it leaks utf8proc's internal numbering and, crucially, it CANNOT tell
-- Canonical from None (both are 0; see Decomposition_Type below). Exposed for
-- callers who want the bare enum; the UCD-faithful value is Decomposition_Type.
::Method utf8proc_Decomposition_Type Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  Return .RexxUnicodeServices~codepointDecompositionType(X2D(code))

-- utf8proc_codepointBoundClass: the RAW utf8proc grapheme-cluster break class
-- (utf8proc_boundclass_t), an integer. This is NOT the UCD Grapheme_Cluster_Break
-- property: utf8proc uses its own numbering and folds into the same enum what the
-- UCD splits between Grapheme_Cluster_Break and Indic_Conjunct_Break (the GB9c
-- aksara/virama classes). There is no faithful name-to-name UCD mapping, so we
-- expose the bare enum and keep the full native name (utf8proc_ prefix + the
-- original method name) to signal exactly whose taxonomy this is. The
-- UCD-faithful per-codepoint break property lives in the table layer (gcb.cls),
-- against which this is meant to be contrasted.
::Method utf8proc_codepointBoundClass Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  Return .RexxUnicodeServices~codepointBoundClass(X2D(code))

-- utf8proc_codepointControlBoundary: utf8proc's "is this a control that forces a
-- grapheme boundary" predicate (1/0), used internally for UAX#29 GB4/GB5. Not a
-- named UCD property: empirically it is General_Category in {Cc,Cf,Zl,Zp} MINUS
-- the joiners {ZWNJ U+200C, ZWJ U+200D} -- utf8proc excludes the joiners because
-- their role in segmentation is to JOIN, not to break. A collapsed view of the
-- boundClass taxonomy (classes CR/LF/Control/format), exposed raw under the full
-- native name for the same reason as its twin above.
::Method utf8proc_codepointControlBoundary Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  Return .RexxUnicodeServices~codepointControlBoundary(X2D(code))

-- Decomposition_Type (dt): the UCD property, long-form value names.
-- utf8proc's enum FUSES Canonical with None (both report 0), because utf8proc
-- only carries Decomposition_Type for COMPATIBILITY decompositions (1..16) and
-- leaves canonical/no-decomposition as 0. We recover the distinction the only
-- way the binding allows: when the enum is 0, ask NFD. If NFD changes the
-- single codepoint, it HAS a (canonical) decomposition -> Canonical; otherwise
-- it has none -> None. Enum 1..16 map directly to the UCD long names below.
-- Verified live against the executor across the whole BMP (one exemplar per
-- enum value). Note: the UCD formally leaves Decomposition_Type empty for
-- canonical decompositions; "Canonical" here is the conventional value name
-- (alias Can) that the facade exposes, matching the native enum surface.
::Method dt                 Class
  Forward Message "Decomposition_Type"
::Method Decomposition_Type Class
  Use Strict Arg code
  If code[1] == "00"X, code~length == 4 Then code = C2X(code[2,3])
  n = X2D(code)
  enum = .RexxUnicodeServices~codepointDecompositionType(n)
  If enum == 0 Then Do
    -- 0 means either None or Canonical. Probe NFD of the lone codepoint.
    bytes = .RexxUnicodeServices~utf8EncodeCodepoint(n, .MutableBuffer~new, >sz)
    nfd   = .RexxUnicodeServices~utf8Transform(bytes~string, .false, .false, 0, 2)
    If nfd~string \== bytes~string Then Return "Canonical"
    Return "None"
  End
  Return self~DecompositionTypeNames[enum]

-- Maps the utf8proc compatibility enum (1..16) to UCD Decomposition_Type
-- long-form value names. Index 0 is never read here (handled above).
::Method DecompositionTypeNames Class Private
  Return .Array~of( -                      -- 1-based; [1] is enum value 1
    "Font", "No_Break", "Initial", "Medial", "Final", "Isolated", "Circle", -
    "Super", "Sub", "Vertical", "Wide", "Narrow", "Small", "Square", -
    "Fraction", "Compat" )

--------------------------------------------------------------------------------
-- String functions (NOT per-codepoint properties: these take a string and    --
-- return a string). Delegate to .RexxUnicodeServices~utf8Transform. Full     --
-- argument order, confirmed against the source of truth                      --
-- (RexxUnicodeServices_test.rex):                                            --
--   utf8Transform(string, casefold, lump, nlf, normalization,                --
--                 stripCC, stripIgnorable, stripMark)                        --
-- Normalization codes: NFC=1, NFD=2, NFKC=3, NFKD=4. utf8Transform consumes  --
-- and produces raw UTF-8 bytes; ~makestring yields those bytes for both      --
-- String and .Codepoints inputs, and class~new rebuilds the result in the    --
-- same class the facade received, matching the table class contract.         --
-- toNFKC/toNFKD have no table equivalent: utf8proc is their only provider.   --
-- toCasefold is Unicode-standard Default Case Folding (ch. 3.13): full case  --
-- fold, e.g. "Straße" and "STRASSE" both fold to "strasse".                  --
--------------------------------------------------------------------------------

::Method toNFC  Class
  Use Strict Arg string
  Return self~Normalize( string, 1 )

::Method toNFD  Class
  Use Strict Arg string
  Return self~Normalize( string, 2 )

::Method toNFKC Class
  Use Strict Arg string
  Return self~Normalize( string, 3 )

::Method toNFKD Class
  Use Strict Arg string
  Return self~Normalize( string, 4 )

::Method toCasefold Class
  Use Strict Arg string
  -- casefold is the FIRST positional argument; no normalization applied.
  result = .RexxUnicodeServices~utf8Transform( string~makestring, .true )
  Return string~class~new( result )

::Method Normalize Class Private
  Use Strict Arg string, normalization
  result = .RexxUnicodeServices~utf8Transform( string~makestring, .false, .false, 0, normalization )
  Return string~class~new( result )