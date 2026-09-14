local api = vim.api

local M = {}

local ns = api.nvim_create_namespace 'nvcheatsheet'
local augroup = api.nvim_create_augroup('kickstart-nvcheatsheet', { clear = true })

local state = {
  buf = nil,
  tab = nil,
  win = nil,
}

local ascii_header = {
  '                                      ',
  '                                      ',
  '                                      ',
  '█▀▀ █░█ █▀▀ ▄▀█ ▀█▀ █▀ █░█ █▀▀ █▀▀ ▀█▀',
  '█▄▄ █▀█ ██▄ █▀█ ░█░ ▄█ █▀█ ██▄ ██▄ ░█░',
  '                                      ',
  '                                      ',
  '                                      ',
}

local color_names = {
  'blue',
  'red',
  'green',
  'yellow',
  'orange',
  'baby_pink',
  'purple',
  'white',
  'cyan',
  'vibrant_green',
  'teal',
}

local cards = {
  {
    title = 'general',
    items = {
      { 'save file', ':w' },
      { 'quit window', ':q' },
      { 'save and quit', ':wq' },
      { 'quit all without saving', ':qa!' },
      { 'reload file from disk', ':e!' },
      { 'open help', ':help {topic}' },
      { 'run health checks', ':checkhealth' },
      { 'plugin manager', ':Lazy' },
      { 'tool installer', ':Mason' },
      { 'open tutor', ':Tutor' },
    },
  },
  {
    title = 'telescope',
    items = {
      { 'find files', '<leader>sf' },
      { 'find hidden files', '<leader>sF' },
      { 'live grep', '<leader>sg' },
      { 'search help', '<leader>sh' },
      { 'search keymaps', '<leader>sk' },
      { 'search diagnostics', '<leader>sd' },
      { 'recent files', '<leader>s.' },
      { 'open buffers', '<leader><leader>' },
      { 'search current buffer', '<leader>/' },
    },
  },
  {
    title = 'lspconfig',
    items = {
      { 'go to definition', 'gd' },
      { 'find references', 'gr' },
      { 'go to implementation', 'gI' },
      { 'hover docs', 'K' },
      { 'rename symbol', '<leader>rn' },
      { 'code action', '<leader>ca' },
      { 'show diagnostics', '<leader>e' },
      { 'prev diagnostic', '[d' },
      { 'next diagnostic', ']d' },
    },
  },
  {
    title = 'files',
    items = {
      { 'toggle neo-tree', '<leader>t' },
      { 'plugin manager', ':Lazy' },
      { 'tool installer', ':Mason' },
      { 'format buffer', 'format on save' },
    },
  },
  {
    title = 'markdown',
    items = {
      { 'enable render markdown', '<leader>me' },
      { 'disable render markdown', ':RenderMarkdown disable' },
      { 'toggle cheatsheet', '<leader>?' },
    },
  },
  {
    title = 'claude',
    items = {
      { 'toggle claude', '<leader>ac' },
      { 'focus claude', '<leader>af' },
    },
  },
  {
    title = 'debug',
    items = {
      { 'continue', '<F5>' },
      { 'step into', '<F1>' },
      { 'step over', '<F2>' },
      { 'step out', '<F3>' },
      { 'toggle breakpoint', '<leader>b' },
    },
  },
  {
    title = 'windows',
    items = {
      { 'move left', '<C-h>' },
      { 'move down', '<C-j>' },
      { 'move up', '<C-k>' },
      { 'move right', '<C-l>' },
      { 'exit terminal mode', '<Esc><Esc>' },
      { 'close cheatsheet', 'q / <Esc>' },
    },
  },
}

local function display_width(text)
  return vim.fn.strdisplaywidth(text)
end

local function palette()
  local fallback = {
    bg = '#16161e',
    bg_highlight = '#24283b',
    fg = '#c0caf5',
    blue = '#7aa2f7',
    red = '#f7768e',
    green = '#9ece6a',
    yellow = '#e0af68',
    orange = '#ff9e64',
    purple = '#bb9af7',
    cyan = '#7dcfff',
    teal = '#73daca',
    white = '#c0caf5',
  }

  local ok, colors = pcall(require, 'tokyonight.colors')
  if not ok then
    return vim.tbl_extend('force', {}, fallback, {
      baby_pink = fallback.red,
      vibrant_green = fallback.green,
      black = fallback.bg,
      black2 = fallback.bg_highlight,
    })
  end

  local c = colors.setup()
  return {
    bg = c.bg_dark or c.bg or fallback.bg,
    bg_highlight = c.bg_highlight or c.bg_popup or fallback.bg_highlight,
    fg = c.fg or fallback.fg,
    blue = c.blue or fallback.blue,
    red = c.red or fallback.red,
    green = c.green or fallback.green,
    yellow = c.yellow or fallback.yellow,
    orange = c.orange or fallback.orange,
    purple = c.magenta or c.purple or fallback.purple,
    cyan = c.cyan or fallback.cyan,
    teal = c.teal or c.blue1 or fallback.teal,
    white = c.fg or fallback.white,
    baby_pink = c.magenta2 or c.magenta or fallback.red,
    vibrant_green = c.green1 or c.green or fallback.green,
    black = c.bg_dark or c.bg or fallback.bg,
    black2 = c.bg_highlight or c.bg_popup or fallback.bg_highlight,
  }
end

local function set_highlights()
  local colors = palette()

  api.nvim_set_hl(0, 'NvChNormal', { fg = colors.fg, bg = colors.bg })
  api.nvim_set_hl(0, 'NvChSection', { bg = colors.black2 })
  api.nvim_set_hl(0, 'NvChAsciiHeader', { fg = colors.blue, bg = 'NONE', bold = true })

  for _, name in ipairs(color_names) do
    api.nvim_set_hl(0, 'NvChHead' .. name, {
      fg = colors.black,
      bg = colors[name],
      bold = true,
    })
  end
end

local function section_line(text, width)
  return {
    { text .. string.rep(' ', math.max(width - display_width(text), 0)), 'NvChSection' },
  }
end

local function chip_line(title, width, highlight)
  local label = ' ' .. title .. ' '
  local label_width = display_width(label)
  local left = math.floor((width - label_width) / 2)
  local right = math.max(width - label_width - left, 0)

  return {
    { string.rep(' ', left), 'NvChSection' },
    { label, highlight },
    { string.rep(' ', right), 'NvChSection' },
  }
end

local function max_mapping_width()
  local width = 0

  for _, card in ipairs(cards) do
    for _, item in ipairs(card.items) do
      width = math.max(width, display_width(item[1] .. item[2]))
    end
  end

  return width
end

local function build_entries(column_width)
  local emptyline = string.rep(' ', column_width)
  local entries = {}

  for index, card in ipairs(cards) do
    local entry = {
      chip_line(card.title, column_width, 'NvChHead' .. color_names[((index - 1) % #color_names) + 1]),
    }

    for _, item in ipairs(card.items) do
      local padding = math.max(column_width - 4 - display_width(item[1] .. item[2]), 1)
      local pretty = item[1] .. string.rep(' ', padding) .. item[2]

      table.insert(entry, { { emptyline, 'NvChSection' } })
      table.insert(entry, { { '  ' .. pretty .. '  ', 'NvChSection' } })
    end

    table.insert(entry, { { emptyline, 'NvChSection' } })
    table.insert(entry, { { emptyline } })
    table.insert(entries, entry)
  end

  return entries
end

local function prepare_buffer(buf, total_lines, width)
  local lines = {}
  local fill = string.rep(' ', math.max(width, 1))

  for _ = 1, total_lines do
    table.insert(lines, fill)
  end

  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.bo[buf].modifiable = false
end

local function render_header(buf, width)
  for row, line in ipairs(ascii_header) do
    local col = math.max(math.floor((width - display_width(line)) / 2), 0)
    api.nvim_buf_set_extmark(buf, ns, row - 1, col, {
      virt_text = { { line, 'NvChAsciiHeader' } },
      virt_text_pos = 'overlay',
    })
  end
end

local function render_cards(buf, win)
  local textoff = vim.fn.getwininfo(win)[1].textoff or 0
  local width = api.nvim_win_get_width(win)
  local available_width = math.max(width - textoff - 6, 20)
  local min_column_width = max_mapping_width() + 10
  local columns = math.floor(available_width / min_column_width)

  if columns < 1 then
    columns = 1
  end

  columns = math.min(columns, #cards)

  local column_width = math.floor((available_width - (min_column_width * columns)) / columns) + min_column_width
  local entries = build_entries(column_width)
  local column_heights = {}
  local laid_out = {}

  for index = 1, columns do
    column_heights[index] = 0
    laid_out[index] = {}
  end

  for index, entry in ipairs(entries) do
    local column = ((index - 1) % columns) + 1
    table.insert(laid_out[column], entry)
    column_heights[column] = column_heights[column] + #entry
  end

  local header_height = #ascii_header
  local total_lines = header_height

  for _, count in ipairs(column_heights) do
    total_lines = math.max(total_lines, header_height + count + 1)
  end

  prepare_buffer(state.buf, total_lines, width)
  render_header(buf, width)

  local left_padding = math.max(math.floor((width - ((columns * column_width) + ((columns - 1) * 2))) / 2), 0)

  for column_index, entries_in_column in ipairs(laid_out) do
    local row = header_height - 1
    local col = left_padding + ((column_index - 1) * (column_width + 2))

    for _, entry in ipairs(entries_in_column) do
      for line_index, chunks in ipairs(entry) do
        api.nvim_buf_set_extmark(buf, ns, row + line_index, col, {
          virt_text = chunks,
          virt_text_pos = 'overlay',
        })
      end

      row = row + #entry
    end
  end
end

local function cleanup()
  state.buf = nil
  state.tab = nil
  state.win = nil
end

local function close()
  if state.tab and api.nvim_tabpage_is_valid(state.tab) then
    local current = api.nvim_get_current_tabpage()
    if current ~= state.tab then
      api.nvim_set_current_tabpage(state.tab)
    end
    vim.cmd 'tabclose'
  else
    cleanup()
  end
end

local function configure_window(buf, win)
  pcall(api.nvim_buf_set_name, buf, 'NvCheatsheet')

  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buflisted = false
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].modifiable = false
  vim.bo[buf].swapfile = false

  vim.wo[win].colorcolumn = ''
  vim.wo[win].cursorline = false
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].list = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].spell = false
  vim.wo[win].wrap = false
  vim.wo[win].winhighlight = 'Normal:NvChNormal,EndOfBuffer:NvChNormal,NormalNC:NvChNormal'
end

local function setup_autocmds(buf)
  api.nvim_clear_autocmds { group = augroup }

  api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
    group = augroup,
    callback = function()
      if state.buf == buf and state.win and api.nvim_win_is_valid(state.win) then
        render_cards(buf, state.win)
      end
    end,
  })

  api.nvim_create_autocmd('BufWipeout', {
    group = augroup,
    buffer = buf,
    callback = function()
      cleanup()
    end,
  })
end

function M.toggle()
  if state.tab and api.nvim_tabpage_is_valid(state.tab) then
    close()
    return
  end

  set_highlights()
  vim.cmd 'tabnew'

  local buf = api.nvim_get_current_buf()
  local win = api.nvim_get_current_win()

  state.buf = buf
  state.tab = api.nvim_get_current_tabpage()
  state.win = win

  configure_window(buf, win)
  render_cards(buf, win)
  setup_autocmds(buf)

  vim.keymap.set('n', 'q', close, { buffer = buf, desc = 'Close cheatsheet', silent = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, desc = 'Close cheatsheet', silent = true })
end

api.nvim_create_user_command('NvCheatsheet', M.toggle, { desc = 'Toggle Neovim cheatsheet' })
vim.keymap.set('n', '<leader>?', M.toggle, { desc = 'Toggle cheatsheet' })

return M
