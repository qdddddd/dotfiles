require('utils')
vim.lsp.enable({ 'csharp_ls', 'r_language_server' })

Au('LspAttach', {
    group = AuGrp('UserLspConfig'),
    pattern = { "*.cs", "*.R" },
    callback = function(args)
        vim.api.nvim_del_augroup_by_id('coc_user_defined')
        vim.cmd([[ CocDisable ]])

        -- Keymappings
        local opts = { buffer = args.buf }
        Keymap('n', '<leader>ho', vim.lsp.buf.hover, opts)
        Keymap('n', '<leader>fo', function() vim.lsp.buf.format { async = true } end, opts)
        Keymap('n', '<leader>fi', vim.lsp.buf.code_action, opts)
        Keymap('n', '<leader>dl', vim.lsp.buf.definition, opts)
        Keymap('n', '<leader>re', vim.lsp.buf.references, opts)
        Keymap('n', '<leader>im', vim.lsp.buf.implementation, opts)
        Keymap('n', '<leader>rn', vim.lsp.buf.rename, opts)
        Keymap('n', '<leader>da', vim.diagnostic.setloclist, { noremap = true, silent = true })
        Keymap(
            'n', '<C-j>',
            function() if vim.fn.ListVisible() == 0 then vim.diagnostic.goto_next() else vim.cmd('cnext') end end,
            { noremap = true, silent = true }
        )
        Keymap(
            'n', '<C-k>',
            function() if vim.fn.ListVisible() == 0 then vim.diagnostic.goto_prev() else vim.cmd('cprevious') end end,
            { noremap = true, silent = true }
        )

        -- Diagnostics
        local signs = {
            { name = "DiagnosticSignError", text = "✗", severity = vim.diagnostic.severity.ERROR },
            { name = "DiagnosticSignWarn",  text = "▲", severity = vim.diagnostic.severity.WARN },
            { name = "DiagnosticSignHint",  text = "◇", severity = vim.diagnostic.severity.HINT },
            { name = "DiagnosticSignInfo",  text = "●", severity = vim.diagnostic.severity.INFO },
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
        SetHl("DiagnosticSignError", GetHl("GruvboxRed").foreground, nil)
        SetHl("DiagnosticSignWarn", GetHl("GruvboxYellow").foreground, nil)
        SetHl("DiagnosticSignHint", GetHl("GruvboxYellow").foreground, nil)
        SetHl("DiagnosticSignInfo", GetHl("GruvboxAqua").foreground, nil)

        -- Signatures
        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
            vim.lsp.handlers.signature_help, {
                border = nil,
                max_width = 90,
                focusable = false,
            }
        )
        Au({ "CursorHoldI" }, {
            group = AuGrp("CsLspSignature"),
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
        Keymap('i', '<CR>', 'pumvisible() ? deoplete#close_popup() : "\\<CR>"', o)
        Keymap('i', '<C-d>', 'pumvisible() ? "\\<PageDown>" : "\\<C-d>"', o)
        Keymap('i', '<C-u>', 'pumvisible() ? "\\<PageUp>" : "\\<C-u>"', o)
        Keymap('i', '<C-space>', 'deoplete#manual_complete()', o)
    end
})

Au({ "FileType" }, {
    group = AuGrp("CsLspHighlight"),
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
