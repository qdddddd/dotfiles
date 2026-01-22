require("utils")

vim.g.codex_commit_max_chars = 8000
if vim.g.codex_commit_enabled == nil then
    vim.g.codex_commit_enabled = true
end

local function buf_has_message(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for _, line in ipairs(lines) do
        -- Ignore everything below git "scissors" line.
        if line:match("^%s*#?%s*%-+%s*>8%s*%-+%s*$") then
            break
        end
        if line:match("%S") and not line:match("^%s*#") then
            return true
        end
    end
    return false
end

local function buf_get_var(bufnr, name)
    local ok, val = pcall(vim.api.nvim_buf_get_var, bufnr, name)
    if ok then
        return val
    end
    return nil
end

local function buf_set_var(bufnr, name, value)
    pcall(vim.api.nvim_buf_set_var, bufnr, name, value)
end

local function trim(text)
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalize_path(path)
    return vim.fn.fnamemodify(path, ":p")
end

local function path_parent(path)
    return vim.fn.fnamemodify(path, ":h")
end

local function read_first_line(path)
    local ok, lines = pcall(vim.fn.readfile, path)
    if ok and type(lines) == "table" and lines[1] then
        return trim(lines[1])
    end
    return nil
end

local function should_notify(opts)
    if opts and opts.notify then
        return true
    end
    return vim.g.codex_commit_notify == true
end

local function notify(opts, msg, level)
    if not should_notify(opts) then
        return
    end
    local function do_notify()
        vim.notify(msg, level or vim.log.levels.INFO)
    end
    if vim.in_fast_event and vim.in_fast_event() then
        vim.schedule(do_notify)
    else
        do_notify()
    end
end

local function is_enabled(opts)
    if opts and opts.force then
        return true
    end
    return vim.g.codex_commit_enabled == true
end

local function get_repo_root_from_dir(start_dir)
    local result = vim.fn.systemlist({ "git", "-C", start_dir, "rev-parse", "--show-toplevel" })
    if vim.v.shell_error ~= 0 then
        return nil
    end
    local root = result[1]
    if not root or root == "" then
        return nil
    end
    return root
end

local function get_repo_root_from_gitdir(git_dir)
    if not git_dir or git_dir == "" then
        return nil
    end
    local abs = normalize_path(git_dir)
    local stat = vim.uv.fs_stat(abs)
    if not stat then
        return nil
    end
    if stat.type == "file" then
        -- .git file inside worktree root
        return path_parent(abs)
    end
    if vim.fn.fnamemodify(abs, ":t") == ".git" then
        return path_parent(abs)
    end
    local gitdir_file = abs .. "/gitdir"
    if vim.uv.fs_stat(gitdir_file) then
        local line = read_first_line(gitdir_file)
        if line and line ~= "" then
            local target = line:match("^gitdir:%s*(.+)$") or line
            return path_parent(normalize_path(target))
        end
    end
    return nil
end

local function get_repo_root_from_env()
    local work_tree = vim.env.GIT_WORK_TREE
    if type(work_tree) == "string" and work_tree ~= "" then
        return normalize_path(work_tree)
    end
    local git_dir = vim.env.GIT_DIR
    if type(git_dir) == "string" and git_dir ~= "" then
        return get_repo_root_from_gitdir(git_dir)
    end
    return nil
end

local function get_repo_root_from_path(path)
    if path == "" then
        return nil
    end
    local abs = normalize_path(path)
    local git_dir = abs:match("(.*/%.git)/COMMIT_EDITMSG$")
    if git_dir then
        return path_parent(git_dir)
    end
    local worktree_dir = abs:match("(.*/%.git/worktrees/[^/]+)/COMMIT_EDITMSG$")
    if worktree_dir then
        return get_repo_root_from_gitdir(worktree_dir)
    end
    return nil
end

local function build_prompt(diff)
    local extra = vim.g.codex_commit_prompt
    local header =
        "Write a concise git commit message (subject only, imperative mood, max 72 chars). Output only the message.\n\n"
    if type(extra) == "string" and extra ~= "" then
        header = header .. extra .. "\n\n"
    end
    return header .. "Staged diff:\n" .. diff
end

local function get_cmd()
    local cmd = vim.g.codex_commit_cmd
    if cmd == nil then
        cmd = { "codex", "exec" }
    end
    if type(cmd) == "string" then
        cmd = { cmd }
    end
    if cmd[1] == "codex" and cmd[2] == nil then
        table.insert(cmd, 2, "exec")
    end
    return cmd
end

local function codex_available(cmd)
    return vim.fn.executable(cmd[1]) == 1
end

local function cmd_has_flag(cmd, flag)
    for _, item in ipairs(cmd) do
        if item == flag then
            return true
        end
    end
    return false
end

local function with_cd(cmd, root)
    if cmd[1] ~= "codex" then
        return cmd
    end
    if cmd_has_flag(cmd, "-C") or cmd_has_flag(cmd, "--cd") then
        return cmd
    end
    local next_cmd = vim.deepcopy(cmd)
    table.insert(next_cmd, 3, "-C")
    table.insert(next_cmd, 4, root)
    return next_cmd
end

local function run_codex(cmd, prompt, cb)
    local use_stdin = vim.g.codex_commit_stdin
    if use_stdin == nil then
        use_stdin = true
    end

    if vim.system then
        if use_stdin then
            vim.system(cmd, { stdin = prompt, text = true }, function(res)
                cb(res.stdout or "", res.code or 1, res.stderr or "")
            end)
        else
            local cmd_with_prompt = vim.deepcopy(cmd)
            table.insert(cmd_with_prompt, prompt)
            vim.system(cmd_with_prompt, { text = true }, function(res)
                cb(res.stdout or "", res.code or 1, res.stderr or "")
            end)
        end
        return
    end

    local output
    local cmd_str = cmd
    if type(cmd) == "table" then
        local parts = {}
        for _, part in ipairs(cmd) do
            table.insert(parts, vim.fn.shellescape(part))
        end
        cmd_str = table.concat(parts, " ")
    end
    if use_stdin then
        output = vim.fn.system(cmd_str .. " 2>&1", prompt)
    else
        local cmd_with_prompt = vim.deepcopy(cmd)
        table.insert(cmd_with_prompt, prompt)
        local parts = {}
        for _, part in ipairs(cmd_with_prompt) do
            table.insert(parts, vim.fn.shellescape(part))
        end
        output = vim.fn.system(table.concat(parts, " ") .. " 2>&1")
    end
    cb(output or "", vim.v.shell_error, "")
end

local function insert_message(bufnr, message)
    local lines = vim.split(message, "\n", { plain = true })
    while #lines > 0 and lines[#lines]:match("^%s*$") do
        table.remove(lines)
    end
    if #lines == 0 then
        return
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
    buf_set_var(bufnr, "codex_commitmsg_generated", true)
end

local function should_generate(bufnr, path, opts)
    if buf_get_var(bufnr, "codex_commitmsg_generated") then
        return false, "Already generated"
    end
    if buf_has_message(bufnr) then
        return false, "Buffer already has a message"
    end
    if vim.bo[bufnr].modifiable == false then
        return false, "Buffer is not modifiable"
    end
    if not (opts and opts.force) then
        if path == "" then
            return false, "Not a file-backed buffer"
        end
        if not path:match("COMMIT_EDITMSG$") then
            return false, "Not a COMMIT_EDITMSG buffer"
        end
    end
    return true, nil
end

local function generate_commit_message(opts)
    local bufnr = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(bufnr)

    if not is_enabled(opts) then
        notify(opts, "Codex commit messages are disabled", vim.log.levels.WARN)
        return
    end

    local ok, reason = should_generate(bufnr, path, opts)
    if not ok then
        notify(opts, reason, vim.log.levels.WARN)
        return
    end

    local cmd = get_cmd()
    if not codex_available(cmd) then
        notify(opts, "codex not found in PATH", vim.log.levels.WARN)
        return
    end

    local dir = path_parent(path)
    local root =
        get_repo_root_from_env()
        or get_repo_root_from_path(path)
        or get_repo_root_from_dir(dir)
        or get_repo_root_from_dir(vim.fn.getcwd())
    if not root then
        notify(opts, "Not in a git repo", vim.log.levels.WARN)
        return
    end

    local diff = vim.fn.system({ "git", "-C", root, "diff", "--cached" })
    if vim.v.shell_error ~= 0 or diff == "" then
        notify(opts, "No staged changes (git diff --cached is empty)", vim.log.levels.WARN)
        return
    end

    local max_chars = vim.g.codex_commit_max_chars or 8000
    if #diff > max_chars then
        diff = diff:sub(1, max_chars) .. "\n\n[diff truncated]"
    end

    local prompt = build_prompt(diff)
    local run_cmd = with_cd(cmd, root)
    run_codex(run_cmd, prompt, function(output, code, stderr)
        if code ~= 0 then
            local detail = trim(stderr or "")
            if detail == "" then
                detail = trim(output or "")
            end
            local msg = "codex failed with exit code " .. tostring(code)
            if detail ~= "" then
                msg = msg .. ": " .. detail
            end
            notify(opts, msg, vim.log.levels.ERROR)
            return
        end
        local message = trim(output)
        if message == "" then
            notify(opts, "codex returned an empty message", vim.log.levels.WARN)
            return
        end
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end
            if vim.bo[bufnr].modified then
                notify(opts, "Buffer changed before insertion", vim.log.levels.WARN)
                return
            end
            if buf_has_message(bufnr) then
                notify(opts, "Buffer already has a message", vim.log.levels.WARN)
                return
            end
            insert_message(bufnr, message)
            notify(opts, "Inserted codex commit message", vim.log.levels.INFO)
        end)
    end)
end

vim.api.nvim_create_user_command("CodexCommitMsg", function(cmd_opts)
    local bufnr = vim.api.nvim_get_current_buf()
    buf_set_var(bufnr, "codex_commitmsg_generated", false)
    generate_commit_message({ notify = true, force = cmd_opts.bang })
end, { bang = true })

Au({ "BufReadPost", "BufNewFile" }, {
    group = AuGrp("CodexCommitMsg"),
    pattern = "COMMIT_EDITMSG",
    callback = function()
        if vim.g.codex_commit_enabled ~= true then
            return
        end
        generate_commit_message()
    end,
})
