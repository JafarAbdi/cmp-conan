-- Mainly copied from https://github.com/tjdevries/config_manager/blob/master/xdg_config/nvim/after/plugin/cmp_gh_source.lua
local Job = require("plenary.job")

local source = {}

source._documentation = function(self)
  return {
    kind = "plaintext",
    value = string.format(
      "conan: %d.%d.%d",
      self.conan_version.major,
      self.conan_version.minor,
      self.conan_version.patch
    ),
  }
end

source.new = function()
  local self = setmetatable({ cache = {}, conan_version = {} }, { __index = source })
  return self
end

source.complete = function(self, _, callback)
  -- This just makes sure that we only hit the Conan API once per session.
  if vim.tbl_isempty(self.cache) then
    local get_version_job = Job:new({
      "conan",
      "--version",
      on_exit = function(job)
        for _, r in ipairs(job:result()) do
          local major, minor, patch = r:match("Conan version (%d+).(%d+).(%d+)")
          if major and minor and patch then
            self.conan_version = {
              major = major,
              minor = minor,
              patch = patch,
            }
          end
        end
      end,
    })
    get_version_job:after_success(function()
      -- TODO: Support both version 1
      local args
      if self.conan_version.major == "2" then
        args = {
          "search",
          "--format",
          "json",
          "*",
          "-vquiet",
        }
      elseif self.conan_version.major == "1" then
        args = { "search", "--remote", "all", "*" }
      end

      Job
        :new({
          command = "conan",
          args = args,
          on_exit = function(job)
            local result = job:result()

            local items = {}
            -- TODO: Support other remotes
            if self.conan_version.major == "2" then
              local ok, parsed = pcall(vim.json.decode, table.concat(result, ""))
              if not ok then
                vim.notify("Failed to parse conan search result")
                return
              end
              local documentation = self:_documentation()
              for _, conan_recipe_item in ipairs(parsed.conancenter.recipes) do
                table.insert(items, {
                  label = conan_recipe_item,
                  documentation = documentation,
                })
              end
            elseif self.conan_version.major == "1" then
              local documentation = self:_documentation()
              for _, conan_recipe_item in ipairs(result) do
                -- TODO: Support other remotes
                if not conan_recipe_item:match("Remote '(.+):") then
                  table.insert(items, {
                    label = conan_recipe_item,
                    documentation = documentation,
                  })
                end
              end
            end
            callback({ items = items, isIncomplete = false })
            self.cache = items
          end,
        })
        :start()
    end)
    get_version_job:start()
  else
    callback({ items = self.cache, isIncomplete = false })
  end
end

source.is_available = function()
  return vim.fn.expand("%:t") == "conanfile.txt" and vim.fn.executable("conan")
end

source.get_keyword_pattern = function()
  return [[\([^"'\%^<>=~,]\)*]]
end

return source
