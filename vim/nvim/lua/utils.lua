HOME = os.getenv("HOME")

function OSX()
    return vim.fn.has("macunix") == 1
end

function LINUX()
    return vim.fn.has("unix") == 1 and OSX() == 0 and vim.fn.has("win32unix") == 0
end

function Exists(file)
    -- Check if a file or directory exists in this path
    local ok, _, code = os.rename(file, file)
    if not ok then
        if code == 13 then
            -- Permission denied, but it exists
            return true
        end
    end
    return ok
end

function IsDir(path)
    -- Check if a directory exists in this path
    return Exists(path .. "/") -- "/" works on both Unix and Windows
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

Map = vim.api.nvim_set_keymap
Keymap = vim.keymap.set
