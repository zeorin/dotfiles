# shellcheck disable=SC2034
VERSION=@version@

# shellcheck disable=SC1083
parser_definition() {
	setup   REST plus:true help:usage abbr:true -- \
		"Usage: ${2##*/} [options...] newpipe.db" ''
	msg -- 'get playlists from newpipe.db' ''
	msg -- 'Options:'
	flag    LIST  		-l --list                             -- "list local playlists"
	param   PLAYLIST	-p --playlist                         -- "create m3u playlist file from playlist by name"
	flag    ALL			-a --all	                          -- "create m3u playlist files for all playlists"
	disp    :usage 		-h --help
	disp    VERSION 	--version
}

eval "$(getoptions parser_definition - "$0") exit 1"

if [ -z ${1+x} ]; then
	usage
	exit 1
fi

DB="$1"

slugify () {
    echo "$1" | iconv -c -t ascii//TRANSLIT | sed -E -e 's/[^[:alnum:]]+/-/g' -e 's/^-+|-+$//g' | tr '[:upper:]' '[:lower:]'
}

list() {
	sqlite3 "$DB" "select name from playlists"
}

playlist() {
	local name="$1"
	local pl
	pl="$(slugify "$name").m3u"
	cat <<EOF > "$pl"
#EXTM3U
#PLAYLIST:$pl
EOF

	sqlite3 "$DB" <<EOF >> "$pl"
select format('#EXTINF:%d,%z
#EXTART:%z
%z', duration, title, uploader, url) as entry from streams
	inner join playlist_stream_join on streams.uid = playlist_stream_join.stream_id
	inner join playlists on playlists.uid = playlist_stream_join.playlist_id
	where playlists.name = '$name'
EOF

	echo "created $pl"
}

if [ -n "$LIST" ]; then
	list
	exit 0
fi

if [ -n "$PLAYLIST" ]; then
	playlist "$PLAYLIST"
	exit 0
fi

if [ -n "$ALL" ]; then
	list | while read -r line; do playlist "$line"; done
	exit 0
fi
