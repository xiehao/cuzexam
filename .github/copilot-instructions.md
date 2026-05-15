# Copilot instructions for `cuzexam`

## Build and verification

- Use **XeLaTeX**, not pdfLaTeX. The class is built on `ctexart`, and the sample document uses `minted`.
- Smoke-test the repository by compiling the sample document:

  ```bash
  latexmk -xelatex -shell-escape -interaction=nonstopmode -halt-on-error demo.tex
  ```

- Compile a single target `.tex` file the same way:

  ```bash
  latexmk -xelatex -shell-escape -interaction=nonstopmode -halt-on-error path/to/file.tex
  ```

- Clean auxiliary files after a local build:

  ```bash
  latexmk -c demo.tex
  ```

- There is no separate test suite or lint configuration in this repository; compiling a target document is the effective verification path.
- On Linux, `cuzexam.cls` forces Adobe CJK fonts via `ifplatform`. Keep that in mind for CI or container builds: a TeX install alone may not be enough if those fonts are unavailable.

## High-level architecture

- This repository is a **LaTeX class project**. `cuzexam.cls` contains nearly all product logic; `demo.tex` is the integration fixture that demonstrates the supported question types and output modes.
- The class extends `ctexart`, sets page geometry and headers/footers, hardcodes `\graphicspath{{images}}`, and centralizes document metadata through `\cuz...` commands such as `\cuzcourse` and `\cuzexamstage`.
- `\makehead` renders the exam header and optional score table. The score table count is derived from the number of `\makepart` calls recorded through the `.aux` file, so adding or removing major parts requires a rerun; `latexmk` handles this automatically.
- Output mode is controlled by the `answer` and `sheet` class options. The same source document is expected to contain all variants at once:
  - `problem` for the exam body
  - `sheetcontents` for answer-sheet-only content
  - `solution`, `proof`, and `analysis` for answer content
  - `studentanswer` for blank answer space
- Those environments are selectively excluded in `\AtBeginDocument`, so changes to rendering behavior usually require checking both the environment definitions and the exclusion rules together.
- Question-part structure is stateful: every `\makepart` resets the `problem` counter and the fill-in index counter, which is why `\fillindex` numbering restarts per part.

## Key conventions

- Treat `demo.tex` as the canonical usage example when changing `cuzexam.cls`. It shows the expected composition pattern: metadata setup, `\makehead`, repeated `\makepart` sections, then paired `problem` / `solution` / `sheetcontents` / `studentanswer` blocks as needed.
- The class currently executes `\ExecuteOptions{answer}`. That means the implementation default is answer-enabled unless `noanswer` is passed explicitly. Be careful when changing docs or defaults, because README text and class behavior are not perfectly aligned here.
- Multiple-choice layout is intentionally limited to **exactly four options**. The `\options{A}{B}{C}{D}` macro measures the widest option and switches between one-line, two-line, and four-line layouts automatically.
- `sheetcontents` is still authored explicitly, but centralized answer blocks now have dedicated helpers: `\makepickouttable{cols}{prefix}` for judge/single-choice style grids and `\makefillinlist{cols}{prefix}` for column-based fill-in answer lists with automatic underline widths.
- For reusable answers, prefer prefix-based definitions like `\cuzanswerdef{judge}{\yes}` or `\cuzanswerdef{blank}{...}` outside `problem`. Prefix-only refs such as `\pickoutref{judge}` and `\fillindexref{blank}` consume the next stored answer in definition order, while explicit keys like `judge:3` still work when a fixed reference is needed.
- `\pickout`, `\pickoutx`, `\fillin`, `\fillinx`, and `\fillindex` are answer-aware placeholders. They are designed so the same source can render either blanks or filled answers depending on the current mode.
- The minted setup is part of the template contract. Use the predefined minted helpers (for example `cppcode` from `\newminted{cpp}{...}`) and preserve the `escapeinside=@@` pattern when blanks, scoring marks, or other LaTeX need to appear inside code listings.
- Images are expected to live under `images/` and are referenced without that prefix because the class sets `\graphicspath{{images}}`.
