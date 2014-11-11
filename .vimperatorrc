"javascript to hide statusbar
noremap <silent> <F8> :js toggle_bottombar()<CR>
noremap : :js toggle_bottombar('on')<CR>:
noremap o :js toggle_bottombar('on')<CR>o
noremap O :js toggle_bottombar('on')<CR>O
noremap t :js toggle_bottombar('on')<CR>t
noremap T :js toggle_bottombar('on')<CR>t
noremap / :js toggle_bottombar('on')<CR>/
cnoremap <CR> <CR>:js toggle_bottombar('off')<CR>
cnoremap <Esc> <Esc>:js toggle_bottombar('off')<CR>

:js << EOF
function toggle_bottombar(p) {
    var bb = document.getElementById('liberator-bottombar');
    if (!bb)
        return;
    if (p == 'on'){
        bb.style.height = '';
        bb.style.overflow = '';
        return;
    }
    if (p == 'off'){
        bb.style.height = '0px';
        bb.style.overflow = 'hidden';
        return;
    }
    bb.style.height = (bb.style.height == '') ? '0px' : '';
    bb.style.overflow = (bb.style.height == '') ? '' : 'hidden';
}
toggle_bottombar();
EOF
