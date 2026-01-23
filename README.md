# Sentinel based Burrows–Wheeler Transform

This document describes a sentinel-based implementation of the **[Burrows-Wheeler Transform (BWT)](https://en.wikipedia.org/wiki/Burrows%E2%80%93Wheeler_transform)**, including its forward transform, inverse transform, and the underlying concepts.

The sentinel-based approach is the *classical* formulation found in most textbooks and academic papers.

---

## Overview

The **Burrows–Wheeler Transform** is a reversible string transformation that rearranges characters to make the string more amenable to compression. It does **not compress data by itself**, but it greatly improves the effectiveness of compressors such as run-length encoding, Huffman coding, or arithmetic coding.

The key idea is to sort all cyclic rotations of a string and extract the last column of the sorted matrix.

---

## Sentinel Character

A **sentinel character** is a special symbol appended to the input string.

### Sentinel requirements

The sentinel must:

* Appear **exactly once**
* **Not appear anywhere in the input**
* Be **lexicographically smaller** than all other characters

In this implementation, the sentinel is:

```
$
```

---

## Forward Transform (BWT)

### Steps

1. Append the sentinel to the input string
2. Generate all cyclic rotations of the augmented string
3. Sort the rotations lexicographically
4. Extract the **last character of each rotation**

The resulting string is the **BWT-encoded output**.

### Example

Input:

```
BANANA
```

After appending sentinel:

```
BANANA$
```

Sorted rotations:

```
$BANANA
A$BANAN
ANA$BAN
ANANA$B
BANANA$
NA$BANA
NANA$BA
```

Last column (BWT result):

```
ANNB$AA
```

---

## Inverse Transform

The inverse transform reconstructs the original string **without storing an index**.

### Key observations

* The last column (`L`) is the BWT output
* The first column (`F`) is `L` sorted lexicographically
* Each character in `F` corresponds to the same character occurrence in `L`

This relationship is known as the **Last–First (LF) Mapping**.

---

## LF Mapping

For a given position `i` in the first column:

* Let `c = F[i]`
* Count how many times `c` appears before position `i` in `F`
* Find the same numbered occurrence of `c` in `L`

This defines a mapping:

```
LF(i) = j
```

Following this mapping reconstructs the original string.

---

## Reconstruction Algorithm

1. Build arrays for:

   * Last column (`L`)
   * First column (`F`)
   * LF mapping (`Next`)
2. Find the row in `F` containing the sentinel
3. Repeatedly:

   * Follow the LF mapping
   * Append the character to the output
   * Stop when the sentinel is reached

The sentinel acts as both **start marker** and **termination condition**.

---

## Why No Index Is Needed

Unlike index-based BWT implementations, the sentinel-based version:

* Has a **unique starting row** (the sentinel row)
* Has a **natural stopping point** (the sentinel)

This eliminates the need to store or transmit a separate index.

---

## Compilation and Usage

Compile with GNAT (GNU Ada compiler):

```bash
gnatmake burrows_wheeler.adb
```

Run the program:

```bash
./burrows_wheeler
```
---

## Limitations

* Requires a guaranteed-unique sentinel character
* Slightly increases string length
* Less suitable for arbitrary binary data unless escaped



## References

- **[Burrows-Wheeler Transform (BWT)](https://en.wikipedia.org/wiki/Burrows%E2%80%93Wheeler_transform)**

 - **[GNAT](https://en.wikipedia.org/wiki/GNAT)**

- **[Ada](https://en.wikipedia.org/wiki/Ada_(programming_language))**
