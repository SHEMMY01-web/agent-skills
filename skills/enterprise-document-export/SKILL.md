---
name: enterprise-document-export
description: >-
  Programmatic enterprise-grade document generation for Microsoft Word (.docx via docx.js) and
  PDF (via ReportLab / Platypus) distilled from ClearSight and curriculum publishing engines.
  Covers XML hex rules, cell padding/borders, callout styling, ReportLab margin math, 2-pass
  numbered canvas paging, and page-break orphan prevention.
---

# Enterprise Document Export Architecture (Word .docx & ReportLab PDF)

A production-grade design manual for generating publication-ready Microsoft Word (`.docx`) and Adobe PDF documents with consistent branding, structured tables, and page-budget layouts.

---

## 1. When to Activate This Skill
- Generating downloadable executive audit summaries, redlines, or legal contracts in `.docx` format.
- Building multi-page curricula, invoices, or analytics reports in PDF using ReportLab Platypus.
- Preventing document corruption bugs (e.g. Word XML hex color syntax errors).
- Implementing two-pass page numbering ("Page X of Y") and dynamic headers/footers in PDFs.
- Eliminating orphaned section headers or table splits across page breaks using `KeepTogether`.

---

## 2. Microsoft Word (.docx) Programmatic Generation

### 2.1 Critical Rule: Never Include `#` in Hex Colors
Word XML attributes (`w:color`, `w:fill`) treat the `#` character as an illegal token, which corrupts the resulting `.docx` file:

```javascript
// ❌ WRONG: Corrupts Word XML
const BAD_COLOR = '#0357EE';

// ✅ CORRECT: Pure 6-character hex strings
const BRAND_NAVY = '031335';
const BRAND_BLUE = '0357EE';
const ALERT_RED = 'DC2626';
const SLATE_BG   = 'F8FAFC';
const BORDER_CLR = 'CBD5E1';
```

---

### 2.2 Styled Callout / Risk Banner Component
Generate modern, rounded callout blocks with left accent borders in Word:

```javascript
import { Paragraph, TextRun, Table, TableRow, TableCell, WidthType, BorderStyle } from 'docx';

export function createCalloutBanner(title, bodyText, accentColor = '0357EE', bgShading = 'F0F4FF') {
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: {
      top: { style: BorderStyle.NONE },
      bottom: { style: BorderStyle.NONE },
      right: { style: BorderStyle.NONE },
      left: { style: BorderStyle.SINGLE, size: 24, color: accentColor } // 3pt accent border
    },
    rows: [
      new TableRow({
        children: [
          new TableCell({
            shading: { fill: bgShading },
            margins: { top: 180, bottom: 180, left: 240, right: 240 }, // dxa units (20 dxa = 1 pt)
            children: [
              new Paragraph({
                children: [
                  new TextRun({ text: title, bold: true, size: 22, color: accentColor })
                ],
                spacing: { after: 80 }
              }),
              new Paragraph({
                children: [
                  new TextRun({ text: bodyText, size: 20, color: '334155' })
                ]
              })
            ]
          })
        ]
      })
    ]
  });
}
```

---

### 2.3 Safe Client-Side Download Trigger
Sanitize the filename to prevent illegal character crashes on Windows/macOS:

```javascript
import { Packer } from 'docx';

export async function downloadDocx(doc, defaultFilename = 'Document_Export') {
  const blob = await Packer.toBlob(doc);
  const safeFilename = defaultFilename.replace(/[^a-zA-Z0-9_\-]/g, '_') + '.docx';

  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = safeFilename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
```

---

## 3. ReportLab PDF Generation Architecture

### 3.1 Margin & Printable Width Mathematics
Always compute `PRINTABLE_WIDTH` explicitly so table column widths sum up perfectly:

```python
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors

PAGE_WIDTH, PAGE_HEIGHT = A4
MARGIN_LEFT = 45
MARGIN_RIGHT = 45
MARGIN_TOP = 40
MARGIN_BOTTOM = 40

# Total usable horizontal canvas width
PRINTABLE_WIDTH = PAGE_WIDTH - (MARGIN_LEFT + MARGIN_RIGHT) # ~505.27 pt
```

---

### 3.2 Dynamic 2-Pass "Page X of Y" Numbered Canvas
Standard ReportLab canvases do not know the total page count on pass 1. Use a two-pass subclass:

```python
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, total_pages):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#777777"))

        # Footer: Document Title (Left), Page X of Y (Right)
        footer_text = f"Page {self._pageNumber} of {total_pages}"
        self.drawString(MARGIN_LEFT, MARGIN_BOTTOM - 15, "Confidential & Proprietary")
        self.drawRightString(PAGE_WIDTH - MARGIN_RIGHT, MARGIN_BOTTOM - 15, footer_text)
        self.restoreState()
```

---

### 3.3 Flowable Tables & Orphan Prevention
Never place bare text into ReportLab tables (it will overflow cell margins). Wrap cell strings in `Paragraph` flowables and group critical sections with `KeepTogether`:

```python
from reportlab.platypus import Paragraph, Table, TableStyle, KeepTogether, Spacer

def create_table_row(label, text, style):
    # Paragraph automatically wraps within the designated column width
    return [Paragraph(f"<b>{label}</b>", style), Paragraph(text, style)]

# Group header and table together so the table does not break onto the next page alone
card = KeepTogether([
    Paragraph("Section Heading", heading_style),
    Spacer(1, 6),
    Table(data, colWidths=[120, PRINTABLE_WIDTH - 120], style=table_style),
    Spacer(1, 14)
])
```

---

## 4. Verification Checklist
- [ ] Word: Validate that all hex strings are exactly 6 characters without `#`.
- [ ] Word: Open generated file in Microsoft Word and Google Docs to verify table cell padding and border rendering.
- [ ] PDF: Verify footer correctly displays "Page 1 of 5", "Page 2 of 5" up to total pages without manual hardcoding.
- [ ] PDF: Check that headings never appear orphaned at the bottom of a page without their corresponding content.
