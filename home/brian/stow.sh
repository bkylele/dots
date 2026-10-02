# Wrapped by writeShellApplication (strict mode and runtime PATH).
repository="$HOME/dots"
stow_dir="$repository/stow"
targets=(.bashrc .config/kitty/kitty.conf .config/user-dirs.dirs
  .config/nvim/init.lua .config/nvim/lua .config/kak)

if [[ ! -d "$stow_dir/apps" ]]; then
  echo "dots-stow: missing $stow_dir/apps; keep the checkout at ~/dots" >&2
  exit 1
fi

# Validate parents before moving anything; never follow them into store trees.
for parent in .config .config/kitty .config/nvim .local .local/share \
  .local/share/nvim .local/share/nvim/site .local/share/nvim/site/pack \
  .local/state .local/state/dots-stow; do
  if [[ -L "$HOME/$parent" || ( -e "$HOME/$parent" && ! -d "$HOME/$parent" ) ]]; then
    echo "dots-stow: $HOME/$parent must be a real directory; move it aside first" >&2
    exit 1
  fi
done
for target in "${targets[@]}"; do
  if [[ ! -e "$stow_dir/apps/$target" ]]; then
    echo "dots-stow: missing source for $target" >&2
    exit 1
  fi
done

backup_root=""
backup() {
  local target=$1
  if [[ -z "$backup_root" ]]; then
    mkdir -p "$HOME/.local/state/dots-stow"
    backup_root=$(mktemp -d "$HOME/.local/state/dots-stow/backup.XXXXXXXX")
  fi
  mkdir -p "$backup_root/$(dirname "$target")"
  mv -- "$HOME/$target" "$backup_root/$target"
  echo "dots-stow: preserved $target in $backup_root"
}

# Preserve conflicts, including HM links. Never adopt contents into the repo.
for target in "${targets[@]}"; do
  destination="$HOME/$target"
  if [[ -L "$destination" ]]; then
    link=$(readlink "$destination")
    if [[ "$link" = /* ]]; then
      absolute="$link"
    else
      absolute="$(dirname "$destination")/$link"
    fi
    if [[ $(realpath -ms "$absolute") = "$stow_dir/apps/$target" ]]; then
      continue
    fi
  fi
  if [[ -e "$destination" || -L "$destination" ]]; then
    backup "$target"
  fi
done

# Retire the old HM plugin directory only if it contains HM-owned links.
# Preserve the whole directory, including any local additions.
old_plugins=.local/share/nvim/site/pack/dots
if [[ -d "$HOME/$old_plugins/start" ]]; then
  for plugin in "$HOME/$old_plugins/start/"*; do
    if [[ -L "$plugin" && $(readlink "$plugin") == /nix/store/*home-manager-files/* ]]; then
      backup "$old_plugins"
      break
    fi
  done
fi

mkdir -p "$HOME/.config/kitty" "$HOME/.config/nvim"
# Fold kak/ and nvim/lua/ into directory links, keeping Kakoune's plugins writable
# in the checkout and preserving the target list above across repeated runs.
stow --dir="$stow_dir" --target="$HOME" --simulate --restow apps
stow --dir="$stow_dir" --target="$HOME" --restow apps
