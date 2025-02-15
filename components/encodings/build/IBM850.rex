/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/tutor/                                          *
 *     and https://github.com/JosepMariaBlasco/tutor                          *
 * Copyright © 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>    *
 * License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  *
 ******************************************************************************/

-- For IBM850.cls
inFile = "../../UCD/CP850-2.0.0.TXT"

Do While Lines(inFile)
  line = LineIn(inFile)
  If line[1] == "#" Then Iterate
  If line[1] = ""   Then Iterate
  Parse Upper Var line "X"ascii . "0X"cp850 ."#"
  If "00"ascii == cp850 Then Iterate

  Say "  decode.['"ascii"'X ] = '"cp850"'; encode.['"cp850"'] = '"ascii"'X"
End