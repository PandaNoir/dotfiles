has() { type "$1" > /dev/null 2>&1; }
file_exists() { [ -f $1 ]; }
dir_exists() { [ -d $1 ]; }

info() {
  echo -e "\033[0;34m[INFO]\033[0;39m $1"
}
warn() {
  echo -e "\033[0;33m[WARN]\033[0;39m $1"
}

symlink() {
  if ! [ -e "$2" ]; then
    info "create symlink from $DOTDIR/$1 to $2"
    ln -sf "$DOTDIR/$1" "$2"
  fi
}
dir_symlink() {
  for file in `ls -1 "$1"`; do
    if ! [ -e "$2/$file" ]; then
      info "create symlink from $1/$file to $2/$file"
      ln -sf "$1/$file" "$2"
    fi
  done
}