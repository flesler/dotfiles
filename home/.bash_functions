# Shell

# Create a directory and cd to it
function mkc() {
  mkdir -p "$@" && cd "$@"
}

# List files in a directory, sorted by size
function duhs() {
  du -hs $@ | sort -hr
}

# Opens a path or the current directory using the default opener
# USAGE:
# $ e
# $ e ~/etc
function e() {
  #if [ -z "$1" ] ; then
  #  explorer .
  #else
  #  explorer $(winpath "$1")
  #fi
  # Linux version
  xdg-open "${1:-.}"
}

# For Linux
function clip() {
  # Copy alias, copy to both clipboards
  if [ "$#" == 0 ]; then
    xclip -r
    xclip -o | xclip -sel clip
  else
    xclip "$@"
  fi
}

# Take all arguments as a command, execute it and copy to clipboard
# If no argument is provided, copy last command executed to clipboard
# Uses head -c-1 to remove the new line that is always at the end
# USAGE:
# $ c echo 1 2 # "1 2" copied
# $ c          # "echo 1 2" copied
function c() {
  if [ $# == 0 ]; then
    history | tail -n2 | head -n1 | sed 's/^[0-9 ]*//' | head -c-1 | clip
  else
    sh -c "$*" | head -c-1 | clip
  fi
}

# Alias for --help | less
# USAGE:
# $ h grep
function h() {
  $@ --help | less
}

# Edits one of the dotfiles and then re-sources it
# USAGE:
# $ rc       # edit .bashrc
# $ rc alias # edit .bash_aliases
# $ rc input # edit .inputrc
function rc() {
  local name=${1:-bash}
  local editor=${EDITOR:-vi}
  for file in "$name" ".$name" ".${name}rc" ".bash_$name" ".bash_${name}s" ".bash_${name}es"; do
    local path="$HOME/$file"
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
# $ pendrive dir1 dir2 file*
# $ pendrive -z dir1 dir2 file*
# $ pendrive g: -z dir1 dir2 file*
function pendrive() {
  if [ "${1:1:1}" = : ]; then
    local drive=/${1:0:1}
    shift
  else
    # Guess pendrive drive. Might not always work, get highest drive letter
    local drive=$(mount | grep ": " | sort | tail -n1 | cut -d' ' -f3)
  fi

  local tarOpts=
  if [ "${1:0:1}" = "-" ]; then
    tarOpts=$1
    shift
  fi

  if [ $# -eq 1 ]; then
    local file=$(basename "$1")
  else
    local file=$(dirname "$1")
    if [ "$file" = "." ]; then
      file=$(basename "$PWD")
    fi
  fi

  local dest=$drive/$file.tar
  if [[ "$tarOpts" = -*z* ]]; then
    dest=$dest.gz
  fi

  echo "Packing all to $dest..."
  local start=$SECONDS
  GZIP=-9 tar $tarOpts -cf $dest $@
  echo "Took $(( $SECONDS - $start )) second(s)"
}

# Node/NPM

function n() {
  local pref=$1
  # Just n to see the current version
  if [ "$pref" == "" ]; then
    node --version
    return
  fi

  # Can provide just the major or major.minor version
  local ver=$(nvm list | grep -Eo "  v$pref\.[0-9.]+")
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

  local node_ver=$(grep '"node"' package.json | sed -E 's/.+"([0-9.]+)\..+/\1/')
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
  local start=$(date +%s)
  "$@"
  notify-send "$ $(echo $@)" "\nTook $(($(date +%s) - start))s to finish"
}

# mv command but it backups
function mvb() {
  local to=$2
  mv $to $to.bkp && mv $@
}

# Swaps 2 files
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
  local filter=${1:-no_match}
  if [[ *"$1"* = *"/"* ]]; then
    echo "Slashes cannot be included"
    return
  fi
  local file=~/.bash_history
  local before=$(cat $file | wc -l)
  tac $file | grep -vEe 'MFD-|chmod|archived|mkdir|npm ?i|npm ?rm|--help|chown|forget|ollama pull|ollama rm|duhs' -e '^([a-z])$' -e '^(z|e|t|hg|which|eval|ls|echo)\b' -e '\b(stash|pop|cm|cd|cp|rrf?|code|alias|apt)\b' -e '(g|git) (cob?|cmnv|clone|bd|bm|init)\b' \
    | sed -r 's/ +$//g' | sed -n "/$filter/!p" | awk '! seen[$0]++' | tac > /tmp/t && mvb /tmp/t $file
  local after=$(cat $file | wc -l)
  if [ "$after" = "0" ]; then
    echo "Reverting..."
    mv $file{.bkp,}
  fi
  history -c
  history -r

  diff ~/.bash_history{.bkp,} | grep '^<' | sort -u
  echo "Trimmed $file, lines: $before -> $after"
}

# Use Node as a calculator
function calc() {
  local code="${*//x/*}"  # Replace x with *
  code="${code//^/**}"    # Replace ^ with **
  node -pe "with(Math) { $code }"
}

# Re run the last line with sudo (same as sudo !!)
function sd() {
  local line="sudo $(tail -n1 ~/.bash_history)"
  echo $line
  $line
}

# Archive file and/or dirs with tar+gzip
function archive() {
  local dir=$(dirname "$1")
  local dest=$(basename "$1")
  cd "$dir"
  shift
  tar -ac --exclude=node_modules --exclude-vcs -f "$dest.tar.xz" "$dest" "$@"
  cd -
}

# Archive and then delete
function archived() {
  archive "$@"
  rm -rf "$@"
}

# Recompresses a bz2 or xz to gz, without deleting the original
function unarchive() {
  local dest=${1/.tar*/}
  mkdir -p "$dest"
  tar -xaf "$1" -C . # "$dest"
}

function find.replace() {
  local search=$1
  local replace=$2
  grep --exclude-dir={node_modules,.git} -Irlw . -e "$search" |\
    xargs sed -i "s;$search;$replace;g"
}

# Download a youtube video at 1080p to /tmp
function dlyt() {
  # bin=youtube-dl
  local bin=yt-dlp
  local pref="https://www.youtube.com/watch?v="
  local id=$(echo ${1/$pref/} | sed -r 's/&.+//')
  echo "Video ID is $id"
  local formats=$($bin --list-formats "$pref$id")
  # line=$(echo "$formats" | grep -e x1080 -e x1280 | head -n1 | sed -r 's/  +/ /g')
  local line=$(echo "$formats" | grep -v "video only" | grep -e 1280x720 | head -n1 | sed -r 's/  +/ /g')
  # line=$(echo "$formats" | grep -v "video only" | tail -n1 | sed -r 's/  +/ /g')
  echo $line
  if [[ "$line" == "" ]]; then
    echo "No valid format found"
    echo "$formats"
    return
  fi
  echo "Line is $line"
  local ext=$(echo "$line" | cut -d' ' -f2)
  echo "Extension is $ext"
  local format=$(echo "$line" | cut -d' ' -f1)
  echo "Format is $format"
  local url=$($bin --format $format --get-url "$pref$id")
  local out="/tmp/$id.$ext"
  echo "URL is $url"
  echo "Downloading to $out..."
  wget "$url" -O $out
}

function watermark() {
  local src_dir="${1:-.}"
  local gravity="${2:-south-east}"
  local opacity="${3:-40}"
  local dest_dir="$src_dir/${4:-watermarked}"
  mkdir -p "$dest_dir"
  find "$src_dir" -maxdepth 1 -type f | while read f; do
    local dest="$dest_dir/$(basename """$f""")"
    if [ -f "$dest" ]; then
      echo "$dest already exists"
      continue
    fi
    local width=$(identify -format "%w" "$f")
    local height=$(identify -format "%h" "$f")
    local size=$((width < height ? width : height))
    width=$((size*2/5))
    local margin=$((size/80))
    composite -gravity $gravity -dissolve ${opacity}% -geometry "${width}x+${margin}+${margin}" ~/Pictures/Watermarks/1.png "$f" "$dest"
    echo "Watermarked $f into $dest"
    # promptcopy $f $dest > /dev/null
  done
}

# See the diff of $from..$to
function git_diff() {
  local from=${1:-1}
  local to=${2:-$(($from - 1))}
  git diff HEAD~$from..HEAD~$to
}

# Matches files based on their Stable Diffusion prompt info
function promptgrep() {
  local filter=$1
  local dir=${2:-.}
  local sep='======== '
  exiftool -filename -if "\$parameters=~/$filter/i" "$dir" | grep "$sep" | sed "s/$sep//"
}

# Copies Stable Diffusion prompt info from an image to many
function promptcopy() {
  local src=$1
  local prompt=$(identify -format '%[parameters]' $src)
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
  local src_dir=$1
  local dest_dir=$2
  local srcs=$(find "$src_dir" -name '*.png')
  for src in $srcs; do
    local filter=$(echo $src | sed -r 's;.+/([^/]+)\.png;\1;')
    local dests=$(find "$dest_dir" -name "${filter}*.png")
    if [ "$dests" != "" ]; then
      promptcopy $src $dests
    fi
  done
}

# Useful shortcut
function pluck() {
  local filter=$1
  local dir="./${filter}/"
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
  local from=$1
  local home="/home/$USER"
  if [[ "$from" != /* ]]; then
    # If relative, prepending $HOME
    from="$home/$from"
  fi
  local def_to=$( [ -d "$from" ] && echo $(dirname "$from") || echo "$from")
  local to=${2:-$def_to}
  if [[ "$to" != /* ]]; then
    to="$home/$to"
  fi
  echo "Copying $from to $to ..."
  rsync --verbose -a rsync://192.168.0.191:$from $to
}

# Install a package and its types
function npmi() {
  nvm use
  local pkg=$1
  if [ "$pkg" = "" ]; then
    npm install
  else
    local version=${2:-latest}
    npm install $pkg@$version
    npm install -D @types/$pkg@$version
  fi
}

function npmrm() {
  local pkg=$1
  npm rm $pkg
  npm rm -D @types/$pkg
}

function transcribe() {
  local file=$1
  shift
  local venv=~/Applications/whisper/venv
  source $venv/bin/activate
  # @see https://github.com/openai/whisper/blob/ba3f3cd54b0e5b8ce1ab3de13e32122d0d5f98ab/whisper/__init__.py#L17 for models
  # --task {transcribe,translate} --language es --output_format {txt,srt}
  local model=medium # large, medium, small, base, tiny (with .en)
  local start=$(date +%s)
  if [ "$1" == "--diarize" ]; then
    shift
    echo "Running diarization over $file with "$model" model..."
    python ~/Applications/whisper-diarization/diarize.py --whisper-model $model -a "$file" $@
  else
    echo "Running transcription of $file with "$model" model..."
    # TODO: Try FP16?
    whisper "$file" --model $model --model_dir $venv --output_dir /tmp/ --output_format txt $@
  fi
  deactivate
  echo "Transcribing took $(($(date +%s) - start))s to finish"
}

function transcribe_yt() {
  local url=$1
  shift
  local id=$(echo $url | sed 's/^.*=//')
  local format=mp3
  local out=/tmp/$id.$format
  local tmp=${out/$id/$id.tmp}
  if [ ! -f "$out" ]; then
    yt-dlp -x --audio-format $format -o "$tmp" $url
    # Handle potential interruptions
    mv "$tmp" "$out"
  fi
  transcribe $out $@
}

# Pull from HF but fix the name to be shorter
function hf_ollama() {
  local tmp=/tmp/Modelfile
  if [ "$1" = "ollama" ]; then
    shift
  fi
  if [ "$1" = "run" ]; then
    shift
  fi

  local repo=${1#"hf.co/"}
  local path=hf.co/$repo
  local base=$2
  local name=$(echo $repo | cut -d'/' -f2)
  if [ -n "$base" ]; then
    # @see https://huggingface.co/docs/hub/ollama#custom-quantization
    ollama show --modelfile $base > $tmp
    # Replace the FROM line with the base model (in some there's +1)
    sed -i "/^#.*FROM/!{/^FROM /d;}; /^TEMPLATE/ i FROM $path" "$tmp"
    echo "Creating $name from $base, pulling $repo from HF..."
    ollama create $name -f $tmp
  else
    echo "No base model was provided for $repo, this was probably a mistake"
    ollama pull $path
    echo "Copying $path to $name"
    ollama cp $path $name
  fi
  ollama rm $path
}

function hf_ollama2() {
  local tmp=/tmp/Modelfile
  local gguf_file=$1
  local base=$2
  if [ ! -f "$gguf_file" ]; then
    echo "Error: GGUF file $gguf_file does not exist"
    return 1
  fi
  if [ -n "$base" ]; then
    # Use base model's Modelfile and replace FROM
    ollama show --modelfile "$base" > "$tmp"
    # Replace the FROM line with the base model (in some there's +1)
    sed -i "/^#.*FROM/!{/^FROM /d;}; /^TEMPLATE/ i FROM $gguf_file" "$tmp"
  else
    # Create minimal Modelfile with just the GGUF file
    echo "FROM $gguf_file" > "$tmp"
  fi

  # Extract model name from GGUF file (remove .gguf extension)
   # Extract model name from GGUF file (remove .gguf extension)
  local base_name=$(basename "$gguf_file" .gguf)
  # Replace last dash with colon for name:tag format
  local name=$(echo "$base_name" | sed 's/\(.*\)-\(.*\)/\1:\2/')
  echo "Creating model $name from $gguf_file..."
  ollama create "$name" -f "$tmp"
  # rm -f "$tmp"
}

# Safe to prefix anything with `pi &&` command runs only in the Pi
function pi() {
  if [[ "$USER" == "pi" ]]; then
    return 0  # Already on the Pi, continue
  else
    if [ $# -gt 0 ]; then
      echo "Connecting to the PI, re-run again"
    fi
    ssh pi@pi.local
    return 1  # Prevents `&&` command from running on the host
  fi
}

function dns.temp() {
  secs=${1:-10}
  dns.disable && sleep $secs
  dns.enable
}