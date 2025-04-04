# The Unicode properties

```
/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/TUTOR/                                          *
 *     and https://github.com/JosepMariaBlasco/TUTOR                          *
 * Copyright © 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>    *
 * License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  *
 ******************************************************************************/
```

The Unicode.Property class (``properties.cls``) and its subclasses are located in the ``components/properties`` subdirectory.
Unicode.Property makes use of two auxiliary classes, [MultiStageTable](../multi-stage-table/), and [PersistentStringTable](../persistent-string-table/).

Classes implementing concrete Unicode properties should subclass Unicode.Property. It offers a set of common services, including the
generation and loading of compressed two-stage tables to store property values.

Documented subclasses are:

* [Unicode.Normalization](./normalization/).

## The Properties class

TBD
