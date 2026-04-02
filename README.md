# neotex

`neotex` is a NeoVim plugin for editing LaTeX with asynchronous compilation and PDF preview support.

## Features

- Compile the current TeX buffer with `pdflatex`
- Open the generated PDF in a separate viewer
- Forward SyncTeX search from source to PDF
- Reverse SyncTeX support from `zathura` back into NeoVim
- Debounced live compilation for the active TeX buffer
- A minimal `LuaSnip` environment snippet

## Defaults

```lua
require("neotex").setup({
  latex_cmd = "pdflatex",
  pdf_viewer = "zathura",
  build_dir = "build",
  debounce_ms = 500,
  log_level = vim.log.levels.INFO,
})
```

`build_dir` is relative to the TeX file directory unless you pass an absolute path. If it is empty, output files are written beside the source file.

## Keymaps

- `<leader>lc`: compile the current TeX file
- `<leader>lo`: open the generated PDF
- `<leader>lp`: compile, then open the PDF on success
- `<leader>ll`: toggle live compilation
- `<leader>lj`: forward SyncTeX search from cursor to PDF

## Commands

- `:NeoTexCompile`
- `:NeoTexOpen`
- `:NeoTexPreview`
- `:NeoTexForwardSearch`
- `:NeoTexLiveToggle`

## Notes

- Reverse and forward SyncTeX are currently implemented for `zathura`.
- `LuaSnip` is optional. If it is installed, `neotex` registers a simple `env` snippet and tab-jump mappings.
