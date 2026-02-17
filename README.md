# travelers-sudoku

A PowerShell script that generates printable Sudoku booklets designed for Traveler's Notebook inserts.

---

## What it does

Generates a landscape A4 PDF with 4 unique Sudoku puzzles per side. Once printed, folded, and cut, you get a mini booklet that fits perfectly inside a Traveler's Notebook.

Each sheet gives you **8 Sudoku puzzles** across 4 booklet pages. You can generate as many pages as you want in one go.

---

## Requirements

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
How many pages do you want? (each page has 4 Sudokus, printed both sides = 8 per page):
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

1. Open the generated PDF
2. Print **page 1** (Side 1)
3. Flip the paper on the **short edge** and print **page 2** (Side 2)
4. **Fold** at the dashed line — 110mm from the left
5. **Cut** at the dotted line — 220mm from the left
6. Discard the small waste strip on the right

You now have a Traveler's Notebook insert with 2 Sudokus per page.

```
|<-- 110mm -->|<-- 110mm -->|<-- ~77mm -->|
|             |             |             |
|  Sudoku 1   |  Sudoku 3   |   (waste)   |
|             |             |             |
|  Sudoku 2   |  Sudoku 4   |             |
|             |             |             |
      ^fold here     ^cut here
```

---

## Parameters

| Parameter     | Default                  | Description                          |
|---------------|--------------------------|--------------------------------------|
| `-OutputPath` | `.\sudoku_booklet.pdf`   | Where to save the PDF                |
| `-Seed`       | Random                   | Set a seed to reproduce the same puzzles |

---

## License

MIT — free to use, modify, and share.
