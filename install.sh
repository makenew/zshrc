#!/usr/bin/env sh

main () {
  set -e
  set -u

  repo='makenew/zshrc'

  config_home=${XDG_CONFIG_HOME:-$HOME/.config}
  cache_home=${XDG_CACHE_HOME:-$HOME/.config}
  zdotdir="${ZDOTDIR:-${config_home}/zsh}"
  zplug_home="${ZPLUG_HOME:-${config_home}/zplug}"
  zplug_cache_dir="${ZPLUG_CACHE_DIR:-${cache_home}/zplug}"
  dotzshrc="${zdotdir}/.zshrc"

  if [ "${1:-}" == 'dev' ]; then
    dev_mode ${2:-master}
  else
    install_zshrc
  fi
}

install_zshrc () {
  echo -e "\033[32m➤ Installing!   \033[0m"

  command -v zsh >/dev/null 2>&1 \
    && echo -e "\033[32m  ✔ Found         ❰ Zsh ❱   \033[0m" \
    || {
      echo -e "\033[31m  ✘ Missing       ❰ Zsh ❱   \033[0m"
      echo -e "\033[31m✘ Install failed!"
      exit 1
    }

  command -v git >/dev/null 2>&1 \
    && echo -e "\033[32m  ✔ Found         ❰ Git ❱   \033[0m" \
    || {
      echo -e "\033[31m  ✘ Missing       ❰ Git ❱   \033[0m"
      echo -e "\033[31m✘ Install failed!"
      exit 1
    }

  command -v awk >/dev/null 2>&1 \
    && echo -e "\033[32m  ✔ Found         ❰ AWK ❱   \033[0m" \
    || {
      echo -e "\033[31m  ✘ Missing       ❰ AWK ❱   \033[0m"
      echo -e "\033[31m✘ Install failed!"
      exit 1
    }

  if [ -d $zdotdir ]; then
    echo -e "\033[32m  ✔ Exists        ❰ ${zdotdir} ❱   \033[0m"
  else
    echo -e "  ➤ Creating      ❰ ${zdotdir} ❱   \033[0m"

    mkdir -p $zdotdir

    echo -e "\033[32m    ✔ Created     ❰ ${zdotdir} ❱   \033[0m"
  fi

  if [ -d $zplug_home ]; then
    echo -e "\033[32m  ✔ Exists        ❰ ${zplug_home} ❱   \033[0m"
  else
    echo -e "  ➤ Creating      ❰ ${zplug_home} ❱   \033[0m"

    mkdir -p $zplug_home

    echo -e "\033[32m    ✔ Created     ❰ ${zplug_home} ❱   \033[0m"
  fi

  if [ -d $zplug_cache_dir ]; then
    echo -e "\033[32m  ✔ Exists        ❰ ${zplug_cache_dir} ❱   \033[0m"
  else
    echo -e "  ➤ Creating      ❰ ${zplug_cache_dir} ❱   \033[0m"

    mkdir -p $zplug_cache_dir

    echo -e "\033[32m    ✔ Created     ❰ ${zplug_cache_dir} ❱   \033[0m"
  fi

  if [ -e $zplug_home/init.zsh ]; then
    echo -e "\033[32m  ✔ Found         ❰ zplug ❱   \033[0m"
  else
    echo -e "  ➤ Installing    ❰ zplug ❱   \033[0m"

    env git clone https://github.com/zplug/zplug $zplug_home >/dev/null 2>&1

    echo -e "\033[32m    ✔ Installed   ❰ zplug ❱   \033[0m"
  fi

  if [ -f $dotzshrc ] || [ -h $dotzshrc ]; then
    zshrc_line=$(head -n 1 $dotzshrc)

    if [ "$zshrc_line" != "# ${repo}" ]; then
      echo -e "  ➤  Exists       ❰ ${dotzshrc} ❱   \033[0m"

      mv $dotzshrc $dotzshrc.preinstall

      echo -e "\033[32m    ✔ Moved to    ❰ ${dotzshrc}.preinstall ❱   \033[0m"
    else
      rm $dotzshrc
    fi
  fi

  echo -e "  ➤ Installing    ❰ ${dotzshrc} ❱   \033[0m"

  tee $dotzshrc >/dev/null <<EOF
# $repo
export ZSHRC_REPO=$repo

export ZDOTDIR="\${ZDOTDIR:-\${XDG_CONFIG_HOME:-\$HOME/.config}/zsh}"
export ZPLUG_HOME="\${ZPLUG_HOME:-\${XDG_CONFIG_HOME:-\$HOME/.config}/zplug}"
export ZPLUG_CACHE_DIR="\${ZPLUG_CACHE_DIR:-\${XDG_CACHE_HOME:-\$HOME/.cache}/zplug}"

zplug_loadfile="\${ZPLUG_HOME}/repos/$repo/packages.zsh"

if [[ -e \$zplug_loadfile ]]; then
  export ZPLUG_LOADFILE=\$zplug_loadfile
fi

source "\${ZPLUG_HOME}/init.zsh"

if [[ ! -e \$zplug_loadfile ]]; then
  zplug \${ZSHRC_REPO}
  zplug install
  export ZPLUG_LOADFILE=\$zplug_loadfile
  source "\${ZPLUG_HOME}/init.zsh"
fi

zplug \${ZSHRC_REPO}, use:env.zsh

if ! zplug check; then
  zplug install
  echo '[zplug] Updating cache file: this may take up to a minute'
fi

zplug load
EOF

  echo -e "\033[32m    ✔ Installed   ❰ ${dotzshrc} ❱   \033[0m"

  echo
  echo -e "\033[32m✔ Install complete!   \033[0m"
  exit 0
}

dev_mode () {
  f_str[0]="zplug_loadfile=\"\${ZPLUG_HOME}/repos/${repo}/packages.zsh\""
  r_str[0]="zplug_loadfile=\"$(pwd)/packages.zsh\""

  f_str[1]="ZSHRC_REPO=${repo}"
  r_str[1]="ZSHRC_REPO=\"$(pwd), from:local, at:${1:-master}\""

  echo -e "\033[32m➤ Entering development mode!   \033[0m"

  i=0
  while [ $i -lt ${#f_str[@]} ]; do
    sed -i -e "s|${f_str[$i]}|${r_str[$i]}|g" $dotzshrc
    i=$(( i + 1 ))
  done

  echo -e "\033[32m  ✔ New zsh sessions will use zshrc from this directory. \033[0m"
  echo -e "\033[32m  ➤ Run ./install.sh again to exit development mode. \033[0m"
  exit 0
}

main $1 $2
