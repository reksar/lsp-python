#!/bin/bash


return_pylsp() {
  echo $1
  echo 0
  exit 0
}


return_err() {
  echo $2
  echo $1
  exit $1
}


pyenv_python() {
  if [[ -d ~/.pyenv ]]
  then
    echo Trying to check pyenv
    PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init --path)"
    python "$1" && return 0
  fi
  return 1
}


system_python() {
  python "$1" || pyenv_python "$1" || return 1
}


user_python() {
  if [[ -f "~/.bashrc" ]]
  then
    echo Trying to check Python using ~/.bashrc
    . ~/.bashrc && python "$1" && return 0
  fi
  echo Failed to check user Python
  return 1
}


install_pylsp() {
  "$1" -m pip install --upgrade pip \
    && "$1" -m pip install --force-reinstall "python-lsp-server[all]" \
    || return 1
}


venv=$1

if [[ ! "$venv" ]]
then
  return_err 1 "venv arg is not specified"
fi

pylsp=$venv/bin/pylsp

if [[ -f "$pylsp" ]]
then
  return_pylsp "$pylsp"
fi

which pylsp && return_pylsp pylsp

echo [INFO] pylsp is not found.

python=$venv/bin/python
scripts=$(cd "$(dirname "$BASH_SOURCE")" &> /dev/null && pwd)
check_py=$scripts/check.py

if [[ ! -f "$python" ]]
then
  echo [INFO] venv is not found.
  system_python "$check_py" || return_err 2 "Python check failed"

  echo [INFO] Installing venv.
  python -m venv "$venv" || return_err 3 "Unable to create Python venv"
fi

"$python" "$check_py" || return_err 4 "Python check failed"

echo [INFO] Installing pylsp.
install_pylsp "$python" || return_err 5 "Unable to install pylsp"

if [[ ! -f "$pylsp" ]]
then
  return_err 6 "Not found: $pylsp"
fi

return_pylsp "$pylsp"
