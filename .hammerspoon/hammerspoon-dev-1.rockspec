---@diagnostic disable: lowercase-global
rockspec_format = "3.0"

package = "hammerspoon"
version = "dev-1"
source = {
  url = "git+ssh://git@github.com/maia-yeager/home-public.git",
}
description = {
  homepage = "https://github.com/maia-yeager/home-public/tree/main/.hammerspoon",
  license = "MIT",
}

dependencies = {
  "lua >= 5.4",
  "penlight >= 1.14.0-3",
}
