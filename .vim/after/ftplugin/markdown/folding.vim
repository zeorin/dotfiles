function! MarkdownFolds()
	let thisline = getline(v:lnum)
	if match(thisline, '^######') >= 0
		return ">6"
	elseif match(thisline, '^#####') >= 0
		return ">5"
	elseif match(thisline, '^####') >= 0
		return ">4"
	elseif match(thisline, '^###') >= 0
		return ">3"
	elseif match(thisline, '^##') >= 0
		return ">2"
	elseif match(thisline, '^#') >= 0
		return ">1"
	else
		return "="
	endif
endfunction
echom 'Plugin loaded'
setlocal foldmethod=expr
setlocal foldexpr=MarkdownFolds()

function! MarkdownFoldText()
	let foldsize = (v:foldend-v:foldstart)
	return getline(v:foldstart).' ('.foldsize.' lines)'
endfunction
setlocal foldtext=MarkdownFoldText()
