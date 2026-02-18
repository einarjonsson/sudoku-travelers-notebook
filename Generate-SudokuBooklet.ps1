# Generate-SudokuBooklet.ps1
# Creates a landscape A4 PDF with Sudoku puzzles sized for either:
#   - Regular Traveler's Notebook (110mm panels, 4 per side, fold + cut)
#   - Passport Traveler's Notebook (134x98mm, 2 per side, cut only)
#
# REQUIREMENTS:
#   Python 3 installed and in PATH
#   reportlab will be auto-installed if missing

param(
    [string]$OutputPath = ".\sudoku_booklet.pdf",
    [int]$Seed = -1
)

# ── Check Python ──────────────────────────────────────────────────────────────
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) {
    Write-Error "Python is not installed or not in PATH. Please install Python 3 from https://python.org"
    exit 1
}
$pythonExe = $python.Source
Write-Host "Using Python: $pythonExe"

# ── Install reportlab ─────────────────────────────────────────────────────────
Write-Host "Checking for reportlab..."
& $pythonExe -c "import reportlab" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing reportlab..."
    & $pythonExe -m pip install reportlab --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install reportlab. Try running: pip install reportlab"
        exit 1
    }
}

# ── Resolve path and seed ─────────────────────────────────────────────────────
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
if ($Seed -eq -1) {
    $Seed = Get-Random -Maximum 99999
    Write-Host "Using random seed: $Seed  (use -Seed $Seed to regenerate the same puzzles)"
}

# ── Ask size ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "What size Traveler's Notebook do you have?" -ForegroundColor Cyan
Write-Host "  1. Regular  (110mm panels - 4 sudokus per side, fold + cut)"
Write-Host "  2. Passport (134x98mm    - 2 sudokus per side, cut only)"
Write-Host ""
$SizeChoice = Read-Host "Enter 1 or 2"
if ($SizeChoice -ne "1" -and $SizeChoice -ne "2") {
    Write-Error "Invalid choice. Please enter 1 or 2."
    exit 1
}
$IsPassport = ($SizeChoice -eq "2")

# ── Ask how many pages ────────────────────────────────────────────────────────
Write-Host ""
if ($IsPassport) {
    $Pages = Read-Host "How many pages do you want? (each page has 4 sudokus, printed both sides = 8 per page)"
} else {
    $Pages = Read-Host "How many pages do you want? (each page has 4 sudokus, printed both sides = 8 per page)"
}
$Pages = [int]$Pages
if ($Pages -lt 1) {
    Write-Error "Please enter at least 1 page."
    exit 1
}

if ($IsPassport) {
    $TotalPuzzles = $Pages * 8
    $PuzzlesPerSide = 4
} else {
    $TotalPuzzles = $Pages * 8
    $PuzzlesPerSide = 4
}

Write-Host "Generating $TotalPuzzles Sudoku puzzles across $Pages page(s)..."

# ── Python script ─────────────────────────────────────────────────────────────
$pythonScript = @"
import random
from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfgen import canvas
from reportlab.lib import colors

random.seed($Seed)
is_passport = $( if ($IsPassport) { "True" } else { "False" } )
total_puzzles = $TotalPuzzles
pages = $Pages

def mm(x):
    return x * 2.8346456693

# ── Sudoku logic ──────────────────────────────────────────────────────────────

def is_valid(board, row, col, num):
    if num in board[row]: return False
    if num in [board[r][col] for r in range(9)]: return False
    br, bc = 3*(row//3), 3*(col//3)
    for r in range(br, br+3):
        for c in range(bc, bc+3):
            if board[r][c] == num: return False
    return True

def solve(board):
    for r in range(9):
        for c in range(9):
            if board[r][c] == 0:
                nums = list(range(1, 10))
                random.shuffle(nums)
                for n in nums:
                    if is_valid(board, r, c, n):
                        board[r][c] = n
                        if solve(board): return True
                        board[r][c] = 0
                return False
    return True

def generate_sudoku():
    board = [[0]*9 for _ in range(9)]
    solve(board)
    cells = [(r, c) for r in range(9) for c in range(9)]
    random.shuffle(cells)
    for r, c in cells[:45]:
        board[r][c] = 0
    return board

# ── Drawing ───────────────────────────────────────────────────────────────────

def draw_sudoku(c, ox, oy, size, puzzle, number, label_fs=8):
    cell = size / 9
    label = f"Sudoku {number}"
    c.setFont("Helvetica-Bold", label_fs)
    lw = c.stringWidth(label, "Helvetica-Bold", label_fs)
    lx, ly = ox + 1, oy + size + 2
    pad = 1.5
    c.setFillColor(colors.white)
    c.rect(lx - pad, ly - pad, lw + pad*2, label_fs + pad*2, fill=1, stroke=0)
    c.setFillColor(colors.black)
    c.drawString(lx, ly, label)
    for row in range(9):
        for col in range(9):
            val = puzzle[row][col]
            if val != 0:
                x = ox + col * cell
                y = oy + (8 - row) * cell
                nfs = cell * 0.52
                c.setFont("Helvetica", nfs)
                c.setFillColor(colors.black)
                tw = c.stringWidth(str(val), "Helvetica", nfs)
                c.drawString(x + (cell - tw)/2, y + cell*0.22, str(val))
    c.setStrokeColor(colors.black)
    for i in range(10):
        c.setLineWidth(1.5 if i % 3 == 0 else 0.5)
        c.line(ox,          oy + i*cell, ox + size, oy + i*cell)
        c.line(ox + i*cell, oy,          ox + i*cell, oy + size)

# ── Regular layout: 4 per side, fold + cut ────────────────────────────────────

def draw_regular_side(c, puzzles, start_idx, side_label):
    A4w, A4h = landscape(A4)
    col_w    = mm(110)
    margin   = mm(5)
    half_h   = A4h / 2
    sud_size = min(col_w - 2*margin, half_h - mm(14))
    v_gap    = (half_h - sud_size) / 2

    positions = [
        (0, 1, start_idx),
        (0, 0, start_idx + 1),
        (1, 1, start_idx + 2),
        (1, 0, start_idx + 3),
    ]
    for col, row, num in positions:
        ox = col * col_w + margin
        oy = row * half_h + v_gap
        draw_sudoku(c, ox, oy, sud_size, puzzles[num - 1], num)

    # Fold line at 110mm (dashed)
    c.setStrokeColor(colors.Color(0.4, 0.4, 0.4))
    c.setLineWidth(0.7)
    c.setDash([6, 4])
    c.line(col_w, 0, col_w, A4h)

    # Cut line at 220mm (dotted)
    c.setDash([2, 5])
    c.setStrokeColor(colors.Color(0.3, 0.3, 0.3))
    c.line(2*col_w, 0, 2*col_w, A4h)
    c.setDash([])

    # Horizontal centre guide
    c.setStrokeColor(colors.Color(0.8, 0.8, 0.8))
    c.setLineWidth(0.3)
    c.setDash([3, 6])
    c.line(0, A4h/2, 2*col_w, A4h/2)
    c.setDash([])

    # Legend in waste strip
    c.setFont("Helvetica", 5)
    c.setFillColor(colors.Color(0.5, 0.5, 0.5))
    tx = 2*col_w + mm(2)
    c.drawString(tx, A4h/2 + mm(4), "--- fold at 110mm")
    c.drawString(tx, A4h/2,         "... cut at 220mm")
    c.drawString(tx, A4h/2 - mm(4), side_label)

# ── Passport layout: 2 per side, cut only ────────────────────────────────────

def draw_passport_side(c, puzzles, start_idx, side_label):
    A4w, A4h = landscape(A4)
    pw = mm(134)
    ph = mm(98)
    total_w = pw * 2
    total_h = ph * 2
    start_x = (A4w - total_w) / 2
    start_y = (A4h - total_h) / 2
    label_h = mm(8)
    grid_size = min(pw - mm(8), ph - mm(8) - label_h)
    v_offset = (ph - grid_size - label_h) / 2
    h_offset = (pw - grid_size) / 2

    # 4 panels: top-left, top-right, bottom-left, bottom-right
    panels = [
        (0, 1, start_idx),
        (1, 1, start_idx + 1),
        (0, 0, start_idx + 2),
        (1, 0, start_idx + 3),
    ]
    for col, row, num in panels:
        ox = start_x + col * pw + h_offset
        oy = start_y + row * ph + v_offset
        draw_sudoku(c, ox, oy, grid_size, puzzles[num - 1], num, label_fs=7)

    # Border outlines for all 4 panels
    c.setStrokeColor(colors.Color(0.6, 0.6, 0.6))
    c.setLineWidth(0.4)
    for col in range(2):
        for row in range(2):
            c.rect(start_x + col*pw, start_y + row*ph, pw, ph, fill=0, stroke=1)

    # Vertical cut line
    c.setStrokeColor(colors.Color(0.3, 0.3, 0.3))
    c.setLineWidth(0.7)
    c.setDash([2, 5])
    c.line(start_x + pw, start_y - mm(4), start_x + pw, start_y + total_h + mm(4))

    # Horizontal cut line
    c.line(start_x - mm(4), start_y + ph, start_x + total_w + mm(4), start_y + ph)
    c.setDash([])

    # Legend
    c.setFont("Helvetica", 5)
    c.setFillColor(colors.Color(0.5, 0.5, 0.5))
    c.drawCentredString(A4w/2, start_y - mm(6), f"... cut horizontally and vertically at centre | {side_label}")

# ── Main ──────────────────────────────────────────────────────────────────────

puzzles = [generate_sudoku() for _ in range(total_puzzles)]
out = r"""$OutputPath"""
c = canvas.Canvas(out, pagesize=landscape(A4))

if is_passport:
    for p in range(pages):
        base = p * 4
        draw_passport_side(c, puzzles, base + 1, f"Page {p+1} of {pages} - Side 1, print first")
        c.showPage()
        draw_passport_side(c, puzzles, base + 3, f"Page {p+1} of {pages} - Side 2, flip on short edge")
        c.showPage()
else:
    for p in range(pages):
        base = p * 8
        draw_regular_side(c, puzzles, base + 1, f"Page {p+1} of {pages} - Side 1, print first")
        c.showPage()
        draw_regular_side(c, puzzles, base + 5, f"Page {p+1} of {pages} - Side 2, flip on short edge")
        c.showPage()

c.save()
print(f"Saved: {out}")
"@

# ── Run Python ────────────────────────────────────────────────────────────────
$tmpScript = [System.IO.Path]::GetTempFileName() + ".py"
$pythonScript | Out-File -FilePath $tmpScript -Encoding utf8
& $pythonExe $tmpScript
$exitCode = $LASTEXITCODE
Remove-Item $tmpScript -ErrorAction SilentlyContinue

if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS! $Pages page(s) saved to: $OutputPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "INSTRUCTIONS:" -ForegroundColor Cyan
    if ($IsPassport) {
        Write-Host "  1. Print Side 1"
        Write-Host "  2. Flip paper on the SHORT edge and print Side 2"
        Write-Host "  3. Cut along the DOTTED vertical line (centre)"
        Write-Host "  4. Cut along the DOTTED horizontal line (centre)"
        Write-Host "  5. You now have $($Pages * 8) passport-sized Sudoku inserts"
    } else {
        Write-Host "  1. Print Side 1"
        Write-Host "  2. Flip paper on the SHORT edge and print Side 2"
        Write-Host "  3. Fold at the DASHED line (110mm from left)"
        Write-Host "  4. Cut at the DOTTED line  (220mm from left)"
        Write-Host "  5. You now have $($Pages * 8) regular-sized Sudoku inserts"
    }
    Write-Host ""
    if ($IsWindows -or ($PSVersionTable.PSVersion.Major -le 5)) {
        Start-Process $OutputPath -ErrorAction SilentlyContinue
    }
} else {
    Write-Error "PDF generation failed. Check Python output above."
    exit 1
}
