/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/TUTOR/                                          *
 *     and https://github.com/JosepMariaBlasco/TUTOR                          *
 * Copyright © 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>    *
 * License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  *
 ******************************************************************************/

-- For iso-8859-1.cls
inFile = "../../UCD/ISO-8859-1-3.0.0.TXT"

Do While Lines(inFile)
  line = LineIn(inFile)
  If line[1] == "#" Then Iterate
  If line[1] = ""   Then Iterate
  Parse Upper Var line "X"ascii . "0X"iso88591 ."#"
  --If "00"ascii == iso88591 Then Iterate

  If iso88591 == "" Then iso88591 = "00"ascii

  Say "  decode.['"ascii"'X ] = '"iso88591"'; encode.['"iso88591"'] = '"ascii"'X"
End