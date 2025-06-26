HOME = os.getenv("HOME")
Keymap = vim.keymap.set
Au = vim.api.nvim_create_autocmd

function AuGrp(name, opts)
    return vim.api.nvim_create_augroup(name, opts or { clear = true })
end

function OSX()
    return vim.fn.has("macunix") == 1
end

function LINUX()
    return vim.fn.has("unix") == 1 and not OSX() and vim.fn.has("win32unix") == 0
end

function Exists(file)
    return vim.uv.fs_stat(file) ~= nil
end

function SetHl(name, fg, bg)
    local settings = {}
    if fg then settings.foreground = fg end
    if bg then settings.background = bg end
    vim.api.nvim_set_hl(0, name, settings)
end

function SetHlLink(name, linkto, default)
    vim.api.nvim_set_hl(0, name, { link = linkto, default = default or false })
end

function GetHl(name)
    return vim.api.nvim_get_hl_by_name(name, true)
end

function Contains(array, item)
    for _, v in ipairs(array) do
        if v == item then
            return true
        end
    end
    return false
end
