#                     _       _
#  _______  ___  _ __(_)_ __ ( )___     _______ _ ____   __
# |_  / _ \/ _ \| '__| | '_ \|// __|   |_  / _ \ '_ \ \ / /
#  / /  __/ (_) | |  | | | | | \__ \  _ / /  __/ | | \ V /
# /___\___|\___/|_|  |_|_| |_| |___/ (_)___\___|_| |_|\_/

# This is the personal .zenv of Xandor Schiefer.

# This file is licensed under the MIT License. The various plugins are
# licensed under their own licenses. Please see their documentation for more
# information.

# The MIT License (MIT) {{{

# Copyright ⓒ 2016 Xandor Schiefer

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

# }}}

# Add local executables to PATH {{{
	[[ -d "$HOME/.bin" ]] && PATH="$HOME/.bin:$PATH"
	[[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"
# }}}

# Composer {{{
	[[ -d "$HOME/.config/composer/vendor/bin" ]] && PATH="$HOME/.config/composer/vendor/bin:$PATH"
# }}}

# Yarn {{{
	[[ -d "$HOME/.yarn/bin" ]] && PATH="$HOME/.yarn/bin:$PATH"
# }}}

# Cabal {{{
	[[ -d "$HOME/.cabal/bin" ]] && PATH="$HOME/.cabal/bin:$PATH"
# }}}

export PATH
