vim.opt_local.wrap = true
vim.opt_local.linebreak = true

for _, key in ipairs { 'j', 'k' } do
  vim.keymap.set({ 'n', 'x' }, key, function()
    return vim.v.count == 0 and 'g' .. key or key
  end, { buffer = true, expr = true, silent = true, desc = 'Move ' .. (key == 'j' and 'down' or 'up') .. ' a displayed line' })
end

vim.keymap.set('n', '<leader>ms', function()
  vim.wo.spell = not vim.wo.spell
  vim.notify('Spellcheck: ' .. (vim.wo.spell and 'on' or 'off'))
end, { buffer = true, desc = '[M]arkdown [S]pellcheck toggle' })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '|setlocal wrap< linebreak< spell<|silent! nunmap <buffer> j|silent! xunmap <buffer> j'
  .. '|silent! nunmap <buffer> k|silent! xunmap <buffer> k|silent! nunmap <buffer> <leader>ms'
