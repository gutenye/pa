## 1.4.0 (Nov 4, 2012)

**Changes**

  - `Pa.rm`, `Pa.cp` ... doesn't support globbing any more.
  - `Pa.has_ext?(path, ext)` -> `Pa.has_ext?(path, *exts)`
  - `Pa.delete_ext?(path, ext)` -> `Pa.delete_ext?(path, *exts)`

## 1.3.2 (Sep 9, 2012)

**Improvements**

  - `Pa.expand2` and `Pa.real2` support second arguments as `(name, dir=".")` *GutenYe*

## 1.3.0 (Aug 28, 2012)

**Improvements**

  - add `Pa.relative_to?`, `Pa.relative_to2`, `Pa.has_ext?`, `Pa.delete_ext2`, `Pa.add_ext2` *GutenYe*

**Changes**

  - change `Pa.ext2` return from "ext" to ".ext", `Pa.fext2` return from ".ext" to "ext"
  - remove `Pa.fname2`
  - remove `Pa.build2` and change `Pa#build2` to `Pa#change2`
