# sudoku-travelers-notebook

A PowerShell script and web app that generates printable Sudoku booklets designed for Traveler's Notebook inserts.

---

## 🌐 Web App (no install needed!)

Don't want to run a script? Just use the web app — pick your size, choose how many pages, and download a PDF instantly:

**👉 [einarjonsson.github.io/sudoku-travelers-notebook](https://einarjonsson.github.io/sudoku-travelers-notebook)**

---

## What it does

Generates a landscape A4 PDF with Sudoku puzzles sized for either **Regular** or **Passport** Traveler's Notebooks. Once printed and cut (and folded for Regular), you get mini inserts that fit perfectly inside your TN.

---

## Sizes supported

| Size | Layout | Per printed sheet |
|------|--------|-------------------|
| **Regular** | 2 columns × 2 rows, fold + cut | 8 sudokus |
| **Passport** | 2 × 2 grid, cut only | 8 sudokus |

---

## Requirements (script only)

- Windows with PowerShell
- Python 3 installed and in your PATH → [python.org](https://python.org)
- `reportlab` Python package (auto-installed by the script if missing)

---

## Usage

```powershell
.\Generate-SudokuBooklet.ps1
```

The script will prompt you:

```
What size Traveler's Notebook do you have?
  1. Regular  (110mm panels - 4 sudokus per side, fold + cut)
  2. Passport (134x98mm    - 4 sudokus per side, cut only)

Enter 1 or 2:

How many pages do you want?:
```

You can also pass optional parameters:

```powershell
# Custom output path
.\Generate-SudokuBooklet.ps1 -OutputPath "C:\Users\You\Desktop\sudoku.pdf"

# Regenerate the exact same puzzles using a seed
.\Generate-SudokuBooklet.ps1 -Seed 12345
```

---

## How to print and assemble

### Regular TN
1. Print **page 1** (Side 1)
2. Flip the paper on the **short edge** and print **page 2** (Side 2)
3. **Fold** at the dashed line — 110mm from the left
4. **Cut** at the dotted line — 220mm from the left
5. Discard the small waste strip on the right

```
|<-- 110mm -->|<-- 110mm -->|<-- ~77mm -->|
|             |             |             |
|  Sudoku 1   |  Sudoku 3   |   (waste)   |
|             |             |             |
|  Sudoku 2   |  Sudoku 4   |             |
|             |             |             |
      ^fold        ^cut
```

### Passport TN
1. Print **page 1** (Side 1)
2. Flip the paper on the **short edge** and print **page 2** (Side 2)
3. **Cut** along the vertical dotted line (centre)
4. **Cut** along the horizontal dotted line (centre)

```
|<-- 134mm -->|<-- 134mm -->|
|  Sudoku 1   |  Sudoku 2   |  } 98mm
|-------------|-------------|  <-- cut here
|  Sudoku 3   |  Sudoku 4   |  } 98mm
        ^cut here
```

---

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-OutputPath` | `.\sudoku_booklet.pdf` | Where to save the PDF |
| `-Seed` | Random | Set a seed to reproduce the same puzzles |

---

## License

MIT — free to use, modify, and share.
