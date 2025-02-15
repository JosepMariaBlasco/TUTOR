/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/tutor/                                          *
 *     and https://github.com/JosepMariaBlasco/TUTOR                          *
 * Copyright © 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>    *
 * License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  *
 ******************************************************************************/

cr   = "0d"x
lf   = "0a"x
file = "a.file"

Call Stream  file,"c", "open write replace"
Call CharOut file,"one"cr"two"lf"three"cr""lf"four"lf""cr"five"
Call Stream  file,"c","close"

Do i = 1 By 1 While Lines(file) > 0
  line = LineIn(file)
  -- Beware of CR: it "eats" all previous chars and returns to col 1
  Say i":" ChangeStr(cr,line,"_") "('"C2X(line)"'X)"
End
