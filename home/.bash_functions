# Shell

# Create a directory and cd to it
function mkc() {
	mkdir -p "$@" && cd "$@"
}

# Converts one or more Unix paths to absolute Windows form
function winpath() {
	for path; do
		if [ -d "$path" ]; then
			path=`cd "$path" && pwd -W`
		else
			path="$(pwd -W)/$path"
		fi
		echo "$path" | sed 's|/|\\|g'
	done
}

# Opens a path or the current directory using the default opener
# USAGE:
#	$ e
#	$ e ~/etc
function e() {
	#if [ -z "$1" ] ; then
	#	explorer .
	#else
	#	explorer $(winpath "$1")
	#fi
	# Linux version
	xdg-open "${1:-.}"
}

# Pipes stdin into an editor (defaults to $EDITOR or vi)
# USAGE:
#	$ echo "something" | viewstdin
#	$ echo "something" | viewstdin subl
function viewstdin() {
	cmd=${*:-${EDITOR:-vi}}
	tmp=/tmp/${RANDOM}${RANDOM}

	cat >$tmp && $cmd $tmp && rm $tmp
}

# For Linux
function clip() {
	# Copy alias, copy to both clipboards
	if [ "$#" == 0 ]; then
		xclip -r
		xclip -o | xclip -sel clip
	else
		xclip $*
	fi
}

# Take all arguments as a command, execute it and copy to clipboard
# If no argument is provided, copy last command executed to clipboard
# Uses head -c-1 to remove the new line that is always at the end
# USAGE:
#	$ c echo 1 2 # "1 2" copied
#	$ c          # "echo 1 2" copied
function c() {
	if [ $# == 0 ]; then
		history | tail -n2 | head -n1 | sed 's/^[0-9 ]*//' | head -c-1 | clip
	else
		sh -c "$*" | head -c-1 | clip
	fi
}

# Alias for --help | less
# USAGE:
#	$ h grep
function h() {
	$@ --help | less
}

# Config

# Edits one of the dotfiles and then re-sources it
# USAGE:
#	$ rc         # edit .bashrc
#	$ rc aliases # edit .bash_aliases
#	$ rc input   # edit .inputrc
function rc() {
	name=${1:-bash}
	editor=${EDITOR:-vi}
	for file in "$name" ".$name" ".${name}rc" ".bash_$name" ".bash_${name}s" ".bash_${name}es"; do
		path="$HOME/$file"
		if [ -f "$path" ]; then
			echo "editing $file"
			$editor "$path" && . "$path"
			return
		fi
	done

	echo "no file found with that name"
}

# Git

# Commits all files with the provided message and copies it to clipboard
function cm() {
	git add -A && git commit -m "$@" && echo "$1" | clip
}

# IO

# Copies all arguments to the pendrive as a single gzipped tar
# Did a benchmark, copied 2k small files:
# - cp -r : 230 seconds
# - tar   : 4 seconds
# - tar.gz: 1 second
#
# USAGE:
#	$ pendrive dir1 dir2 file*
#	$ pendrive -z dir1 dir2 file*
#	$ pendrive g: -z dir1 dir2 file*
function pendrive() {
	if [ "${1:1:1}" = : ]; then
		drive=/${1:0:1}
		shift
	else
		# Guess pendrive drive. Might not always work, get highest drive letter
		drive=$(mount | grep ": " | sort | tail -n1 | cut -d' ' -f3)
	fi

	tarOpts=
	if [ "${1:0:1}" = "-" ]; then
		tarOpts=$1
		shift
	fi

	if [ $# -eq 1 ]; then
		file=$(basename "$1")
	else
		file=$(dirname "$1")
		if [ "$file" = "." ]; then
			file=$(basename "$PWD")
		fi
	fi

	dest=$drive/$file.tar
	if [[ "$tarOpts" = -*z* ]]; then
		dest=$dest.gz
	fi

	echo "Packing all to $dest..."
	start=$SECONDS
	GZIP=-9 tar $tarOpts -cf $dest $@
	echo "Took $(( $SECONDS - $start )) second(s)"
}

# Node/NPM

function n() {
	pref=$1
	# Just n to see the current version
	if [ "$pref" == "" ]; then
		node --version
		return
	fi

	# Can provide just the major or major.minor version
	ver=$(nvm list | grep -Eo "  v$pref\.[0-9.]+")
	if [ "$ver" == "" ]; then
		>&2 echo "No Node.js version found starting with $pref"
	else
		nvm use $ver
	fi
}

function nr() {
	if [ ! -f "package.json" ]; then
		1>2 echo "No package.json in this directory"
		return
	fi

	node_ver=$(grep '"node"' package.json | sed -E 's/.+"([0-9.]+)\..+/\1/')
	# If current node version doesn't match the requirement, switch
	node -v | grep -q ${node_ver}. || n $node_ver
	npm run -s ${*:-start}
}

# Returns the version of a dependency even if nested
function npmv() {
	find . -path "*/$1/package.json" | xargs grep -H version | sed -E 's/package.json|"version": "|",//g'
}

# Sends a notification after a long running job finishes
function remind(){
  start=$(date +%s)
  "$@"
  notify-send "$ $(echo $@)" "\nTook $(($(date +%s) - start))s to finish"
}

# mv command but it backups
function mvb() {
  to=$2
  mv $to $to.bkp && mv $@
}

# swamps 2 files
function swap() {
  mv $1 $1.bkp
  mv $2 $1
  mv $1.bkp $2
}

# Remove entries matching $1 from the bash history, also remove duplicates
function forget() {
  history -a
  # TODO: Support multi-argument so I don't need to always wrap in quotes?
  # When empty, just clean up the history
  filter=${1:-no_match}
  if [[ *"$1"* = *"/"* ]]; then
    echo "Slashes cannot be included"
    return
  fi
  file=~/.bash_history
  before=$(cat $file | wc -l)
  tac $file | grep -vEe 'MFD-|chmod|archived|mkdir|npm ?i|npm ?rm|apt|--help|chown|forget' -e '^([a-z])$' -e '^(z|e|t|hg|which)\b' -e '\b(cm|cd|cp|rrf?|ls|code|alias|which)\b' -e '(g|git) (cob?|cmnv|clone|bd|bm|init)\b' \
    | sed -r 's/ +$//g' | sed -n "/$filter/!p" | awk '! seen[$0]++' | tac > /tmp/t && mvb /tmp/t $file
  after=$(cat $file | wc -l)
  echo "Trimmed $file, lines: $before -> $after"
  if [ "$after" = "0" ]; then
    echo "Reverting..."
    mv $file{.bkp,}
  fi
  history -c
  history -r

  diff ~/.bash_history{.bkp,} | grep '^<' | sort -u
}

# Use Node as a calculator
function calc() {
	node -pe "with(Math) { $* }"
}

# Re run the last line with sudo (same as sudo !!)
function sd() {
  line="sudo $(tail -n1 ~/.bash_history)"
  echo $line
  $line
}

# Archive file and/or dirs with tar+gzip
function archive() {
  dest=${1//\//}
  tar -ac --exclude=node_modules --exclude-vcs -f "$dest.tar.gz" "$@"
}

# Archive and then delete
function archived() {
  archive "$@"
  rm -r "$@"
}

# Recompresses a bz2 or xz to gz, without deleting the original
function unarchive() {
  dest=${1/.tar*/}
  mkdir -p "$dest"
  tar -xaf "$1" -C . # "$dest"
}

function find.replace() {
	search=$1
	replace=$2
	grep --exclude-dir={node_modules,.git} -Irlw . -e "$search" |\
		xargs sed -i "s;$search;$replace;g"
}

# Download a youtube video at 1080p to /tmp
function dlyt() {
  # bin=youtube-dl
  bin=yt-dlp
  pref="https://www.youtube.com/watch?v="
  id=$(echo ${1/$pref/} | sed -r 's/&.+//')
  echo "Video ID is $id"
  formats=$($bin --list-formats "$pref$id")
  # line=$(echo "$formats" | grep -e x1080 -e x1280 | head -n1 | sed -r 's/  +/ /g')
  # line=$(echo "$formats" | grep -v "video only" | grep -e 1280x720 | head -n1 | sed -r 's/  +/ /g')
  line=$(echo "$formats" | grep -v "video only" | tail -n1 | sed -r 's/  +/ /g')
  echo $line
  if [[ "$line" == "" ]]; then
    echo "No valid format found"
    echo "$formats"
    return
  fi
  echo "Line is $line"
  ext=$(echo "$line" | cut -d' ' -f2)
  echo "Extension is $ext"
  format=$(echo "$line" | cut -d' ' -f1)
  echo "Format is $format"
  url=$($bin --format $format --get-url "$pref$id")
  out="/tmp/$id.$ext"
  echo "URL is $url"
  echo "Downloading to $out..."
  wget "$url" -O $out
}

function watermark() {
  src_dir="${1:-.}"
  gravity="${2:-south-east}"
  opacity="${3:-40}"
  dest_dir="$src_dir/${4:-watermarked}"
  mkdir -p "$dest_dir"
  find "$src_dir" -maxdepth 1 -type f | while read f; do
    dest="$dest_dir/$(basename """$f""")"
    if [ -f "$dest" ]; then
      echo "$dest already exists"
      continue
    fi
    width=$(identify -format "%w" "$f")
    height=$(identify -format "%h" "$f")
    size=$((width < height ? width : height))
    width=$((size*2/5))
    margin=$((size/80))
    composite -gravity $gravity -dissolve ${opacity}% -geometry "${width}x+${margin}+${margin}" ~/Pictures/Watermarks/1.png "$f" "$dest"
    echo "Watermarked $f into $dest"
    # promptcopy $f $dest > /dev/null
  done
}

# See the diff of $from..$to
function git_diff() {
  from=${1:-1}
  to=${2:-$(($from - 1))}
  git diff HEAD~$from..HEAD~$to
}

# Matches files based on their Stable Diffusion prompt info
function promptgrep() {
  filter=$1
  dir=${2:-.}
  sep='======== '
  exiftool -filename -if "\$parameters=~/$filter/i" "$dir" | grep "$sep" | sed "s/$sep//"
}

# Copies Stable Diffusion prompt info from an image to many
function promptcopy() {
  src=$1
  prompt=$(identify -format '%[parameters]' $src)
  if [ "$prompt" = "" ]; then
    echo "No prompt found in $src"
    return
  fi
  shift
  mogrify -set parameters "$prompt" $@
  echo "Copy prompt from $src to $@: $prompt"
}

# Copies Stable Diffusion prompt info from all sources in a dir to all the matching ones in another
function promptcopybatch() {
  src_dir=$1
  dest_dir=$2
  srcs=$(find "$src_dir" -name '*.png')
  for src in $srcs; do
    filter=$(echo $src | sed -r 's;.+/([^/]+)\.png;\1;')
    dests=$(find "$dest_dir" -name "${filter}*.png")
    if [ "$dests" != "" ]; then
      promptcopy $src $dests
    fi
  done
}

# Useful shortcut
function pluck() {
  filter=$1
  dir="./${filter}/"
  mkdir -p $dir
  if [ "$2" = "-m" ]; then
    mv ./*${filter}*.* $dir
    echo "Moved all to $dir"
  else
    cp ./*${filter}*.* $dir
    echo "Copied all to $dir, use -m to move"
  fi
}

# Syncs from the old laptop via rsync
function bring() {
  from=$1
  home="/home/$USER"
  if [[ "$from" != /* ]]; then
    # If relative, prepending $HOME
    from="$home/$from"
  fi
  def_to=$( [ -d "$from" ] && echo $(dirname "$from") || echo "$from")
  to=${2:-$def_to}
  if [[ "$to" != /* ]]; then
    to="$home/$to"
  fi
  echo "Copying $from to $to ..."
  rsync --verbose -a rsync://192.168.0.191:$from $to
}

# Install a package and its types
function npmi() {
  pkg=$1
  version=${2:-latest}
  npm install $pkg@$version
  npm install -D @types/$pkg@$version
}

function npmrm() {
  pkg=$1
  npm rm $pkg
  npm rm -D @types/$pkg
}

function transcribe() {
  file=$1
  shift
  venv=~/Applications/whisper/venv
  source $venv/bin/activate
  # @see https://github.com/openai/whisper/blob/ba3f3cd54b0e5b8ce1ab3de13e32122d0d5f98ab/whisper/__init__.py#L17 for models
  # --task {transcribe,translate} --language es --output_format {txt,srt}
  model=medium # large, medium, small, base, tiny (with .en)
  start=$(date +%s)
  if [ "$1" == "--diarize" ]; then
    shift
    echo "Running diarization over $file with "$model" model..."
    python ~/Applications/whisper-diarization/diarize.py --whisper-model $model -a "$file" $@
  else
    echo "Running transcription of $file with "$model" model..."
    # TODO: Try FP16?
    whisper "$file" --model $model --model_dir $venv --output_dir /tmp/ --output_format srt $@
  fi
  deactivate
  echo "Transcribing took $(($(date +%s) - start))s to finish"
}

function transcribe_yt() {
  url=$1
  shift
  id=$(echo $url | sed 's/^.*=//')
  format=mp3
  out=/tmp/$id.$format
  tmp=${out/$id/$id.tmp}
  if [ ! -f "$out" ]; then
    yt-dlp -x --audio-format $format -o "$tmp" $url
    # Handle potential interruptions
    mv "$tmp" "$out"
  fi
  transcribe $out $@
}

function cursor() {
  bin=~/Applications/cursor-*
  $bin $@ & &>/dev/null
  disown
}