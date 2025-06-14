require 'lspconfig'.csharp_ls.setup {
    cmd = { 'csharp-ls', '--loglevel', 'log' },
    filetypes = { "cs" },
    init_options = {
        AutomaticWorkspaceInit = true
    },
    root_dir = function(_, _)
        return vim.fs.dirname(
            vim.fs.find(
                function(name)
                    return name:match('.*%.sln$')
                end,
                { upward = true, limit = math.huge, type = 'file' }
            )[1]
        )
    end,
    single_file_support = true,
}

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
    pattern = "*.cs",
    callback = function(args)
        vim.api.nvim_del_augroup_by_id(vim.api.nvim_create_augroup('coc_user_defined', { clear = true }))
        vim.cmd([[ CocDisable ]])

        -- Keymappings
        local opts = { buffer = args.buf }
        vim.keymap.set('n', '<leader>ho', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>fo', function() vim.lsp.buf.format { async = true } end, opts)
        vim.keymap.set('n', '<leader>fi', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>dl', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', '<leader>re', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<leader>im', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>da', vim.diagnostic.setloclist, { noremap = true, silent = true })
        vim.keymap.set(
            'n', '<C-j>',
            function() if vim.fn.ListVisible() == 0 then vim.diagnostic.goto_next() else vim.cmd('cnext') end end,
            { noremap = true, silent = true }
        )
        vim.keymap.set(
            'n', '<C-k>',
            function() if vim.fn.ListVisible() == 0 then vim.diagnostic.goto_prev() else vim.cmd('cprevious') end end,
            { noremap = true, silent = true }
        )

        -- Diagnostics
        local signs = {
            { name = "DiagnosticSignError", text = "✗", severity = vim.diagnostic.severity.ERROR },
            { name = "DiagnosticSignWarn", text = "▲", severity = vim.diagnostic.severity.WARN },
            { name = "DiagnosticSignHint", text = "◇", severity = vim.diagnostic.severity.HINT },
            { name = "DiagnosticSignInfo", text = "●", severity = vim.diagnostic.severity.INFO },
        }

        for _, sign in ipairs(signs) do
            vim.fn.sign_define(sign.name, { text = sign.text, texthl = sign.name, numhl = sign.name })
        end

        local function sign_mappings(name)
            local ret = {}
            for _, sign in ipairs(signs) do
                ret[sign.severity] = sign[name]
            end
            return ret
        end

        vim.diagnostic.config({
            virtual_text = false,
            signs = {
                text = sign_mappings("text"),
                numhl = sign_mappings("name"),
            },
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = {
                scope = "line",
                focusable = true,
                source = "always",
                border = nil,
                header = "",
                prefix = "",
                max_width = 90,
                wrap = true
            },
        })

        SetHlLink("NormalFloat", "Fmenu")
        SetHl("DiagnosticError", GetHl("GruvboxRed").foreground, nil)
        SetHl("DiagnosticWarn", GetHl("GruvboxYellowSign").foreground, nil)
        SetHl("DiagnosticHint", GetHl("GruvboxYellowSign").foreground, nil)
        SetHl("DiagnosticInfo", GetHl("GruvboxAquaSign").foreground, nil)
        SetHl("FloatBorder", GetHl("VertSplit").foreground, GetHl("Fmenu").background)
        SetHlLink("@lsp.type.namespace", "GruvboxAqua")
        SetHlLink("DiagnosticFloatingError", "DiagnosticError")
        SetHlLink("DiagnosticFloatingWarn", "DiagnosticWarn")
        SetHlLink("DiagnosticFloatingHint", "DiagnosticHint")
        SetHlLink("DiagnosticFloatingInfo", "DiagnosticInfo")

        -- Signatures
        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
            vim.lsp.handlers.signature_help, {
                border = nil,
                max_width = 90,
                focusable = false,
            }
        )
        vim.api.nvim_create_autocmd({ "CursorHoldI" }, {
            group = vim.api.nvim_create_augroup("CsLspSignature", {}),
            pattern = "*.cs",
            callback = function(_) vim.lsp.buf.signature_help() end
        })

        -- Completion
        vim.g['deoplete#lsp#handler_enabled'] = true
        vim.g['deoplete#lsp#use_icons_for_candidates'] = true
        vim.fn['deoplete#custom#option']({
            num_processes = -1,
        })
        vim.fn['deoplete#custom#source']('_', {
            min_pattern_length = 1,
            smart_case = true,
            show_docstring = 1,
        })
        vim.fn['deoplete#custom#source']('lsp', {
            show_docstring = 1,
        })
        vim.fn['deoplete#enable']()
        vim.fn['deoplete#lsp#enable']()
        local o = { noremap = true, silent = true, expr = true }
        vim.keymap.set('i', '<CR>', 'pumvisible() ? deoplete#close_popup() : "\\<CR>"', o)
        vim.keymap.set('i', '<C-d>', 'pumvisible() ? "\\<PageDown>" : "\\<C-d>"', o)
        vim.keymap.set('i', '<C-u>', 'pumvisible() ? "\\<PageUp>" : "\\<C-u>"', o)
        vim.keymap.set('i', '<C-space>', 'deoplete#manual_complete()', o)
    end
})

vim.api.nvim_create_autocmd({ "FileType" }, {
    group = vim.api.nvim_create_augroup("CsLspHighlight", {}),
    pattern = "cs",
    callback = function(_)
        SetHlLink("csStorage", "GruvboxRed")
        SetHlLink("csClass", "GruvboxRed")
        SetHlLink("csType", "GruvboxRed")
        SetHlLink("csAccessModifier", "GruvboxRed")
        SetHlLink("csInterpolationFormat", "String")
        SetHlLink("Structure", "GruvboxYellow")
    end
})
