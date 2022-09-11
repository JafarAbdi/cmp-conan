# cmp-conan
[![Format](https://github.com/JafarAbdi/cmp-conan/actions/workflows/formant.yaml/badge.svg)](https://github.com/JafarAbdi/cmp-conan/actions/workflows/formant.yaml)

nvim-cmp source for conan package recipes.

![Peek 2022-09-11 12-01](https://user-images.githubusercontent.com/16278108/189520355-ad6764f9-5657-4f57-8a04-481d41ed663f.gif)


## Setup

```lua
require'cmp'.setup {
  sources = {
    { name = 'conan_recipes' }
  }
}
```
