return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      auto_install = false,
      -- Explicit list: only these parsers, nothing else, no surprises.
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "bash",
        "markdown",
        "markdown_inline",
        "python",
        "typescript",
        "css",
        "go",
        "rust",
        "html",
        "yaml",
        "json",
        "tsx"
        -- add languages you actually edit, e.g.:
        -- "python", "typescript", "tsx", "javascript", "json", "yaml", "toml",
        -- "html", "css", "go", "rust",
      },
    },
  },
}
