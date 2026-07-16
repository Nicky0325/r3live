#!/usr/bin/env bash

set -euo pipefail

readonly workspace_root="/workspaces/r3live"
readonly catkin_workspace="/home/vscode/r3live_ws"
readonly output_target="/data/output"
readonly output_link="${HOME}/r3live_output"
readonly shell_marker="# >>> r3live devcontainer >>>"

ensure_link() {
  local target="$1"
  local link="$2"

  if [[ -L "${link}" ]]; then
    ln -sfn "${target}" "${link}"
  elif [[ -e "${link}" ]]; then
    printf 'Cannot create symlink %s: a non-symlink path already exists there.\n' "${link}" >&2
    return 1
  else
    ln -s "${target}" "${link}"
  fi
}

mkdir -p "${catkin_workspace}/src" "${output_target}"
ensure_link "${workspace_root}/r3live" "${catkin_workspace}/src/r3live"
ensure_link "${workspace_root}/config" "${catkin_workspace}/src/config"
ensure_link "${output_target}" "${output_link}"

# ROS Noetic environment hooks are not safe under `set -u`; some read an
# optional variable before assigning its default value.
set +u
source /opt/ros/noetic/setup.bash
source /opt/livox_ws/devel/setup.bash
set -u

jobs="${R3LIVE_BUILD_JOBS:-$(nproc)}"
if (( jobs > 4 )); then
  jobs=4
fi

(
  cd "${catkin_workspace}"
  catkin_make -DCMAKE_BUILD_TYPE=Release -j"${jobs}"
)

if ! grep -Fq "${shell_marker}" "${HOME}/.bashrc"; then
  printf '\n%s\n' "${shell_marker}" >> "${HOME}/.bashrc"
  printf '%s\n' 'source /opt/ros/noetic/setup.bash' >> "${HOME}/.bashrc"
  printf '%s\n' 'source /opt/livox_ws/devel/setup.bash' >> "${HOME}/.bashrc"
  printf '%s\n' 'if [[ -f /home/vscode/r3live_ws/devel/setup.bash ]]; then' >> "${HOME}/.bashrc"
  printf '%s\n' '  source /home/vscode/r3live_ws/devel/setup.bash' >> "${HOME}/.bashrc"
  printf '%s\n' 'fi' >> "${HOME}/.bashrc"
  printf '%s\n' '# <<< r3live devcontainer <<<' >> "${HOME}/.bashrc"
fi

printf '\nR3LIVE is ready. Rosbags are available under /data.\n'
printf 'Generated maps and meshes persist in %s.\n' "${output_target}"
