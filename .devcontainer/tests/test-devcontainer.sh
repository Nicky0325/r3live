#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
devcontainer_dir="${repo_root}/.devcontainer"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "missing file: ${1#"${repo_root}/"}"
}

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "${file#"${repo_root}/"} does not contain: ${text}"
}

assert_file "${devcontainer_dir}/devcontainer.json"
assert_file "${devcontainer_dir}/Dockerfile"
assert_file "${devcontainer_dir}/post-create.sh"

python3 - "${devcontainer_dir}/devcontainer.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as stream:
    config = json.load(stream)

assert config["build"]["dockerfile"] == "Dockerfile"
assert config["build"]["context"] == ".."
assert config["remoteUser"] == "vscode"
assert config["updateRemoteUserUID"] is True
assert config["workspaceFolder"] == "/workspaces/r3live"
assert config["postCreateCommand"] == "bash .devcontainer/post-create.sh"
assert config["containerEnv"]["DISPLAY"] == "${localEnv:DISPLAY}"
assert config["containerEnv"]["XAUTHORITY"] == "/home/vscode/.Xauthority"
assert config["containerEnv"]["QT_X11_NO_MITSHM"] == "1"

mounts = "\n".join(config["mounts"])
assert "${localEnv:HOME}/r3live_data" in mounts
assert "target=/data" in mounts
assert "target=/tmp/.X11-unix" in mounts
assert "target=/home/vscode/.Xauthority" in mounts

initialize = config["initializeCommand"]
assert "r3live_data/output" in initialize
assert ".Xauthority" in initialize

extensions = set(config["customizations"]["vscode"]["extensions"])
assert "ms-vscode.cpptools" in extensions
assert "ms-vscode.cmake-tools" in extensions
assert "ms-iot.vscode-ros" in extensions
PY

bash -n "${devcontainer_dir}/post-create.sh"

python3 - "${devcontainer_dir}/post-create.sh" <<'PY'
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    script = stream.read()

assert "set +u" in script, "post-create.sh does not disable nounset before sourcing ROS"
nounset_off = script.index("set +u")
ros_source = script.index("source /opt/ros/noetic/setup.bash")
livox_source = script.index("source /opt/livox_ws/devel/setup.bash")
nounset_on = script.index("set -u", nounset_off)
assert nounset_off < ros_source < livox_source < nounset_on, (
    "ROS overlays must be sourced with nounset disabled because ROS Noetic's "
    "environment hooks read variables before assigning defaults"
)
PY

assert_contains "${devcontainer_dir}/Dockerfile" "FROM osrf/ros:noetic-desktop-full-focal"
assert_contains "${devcontainer_dir}/Dockerfile" "7cf759a760ac674b7032c48b46ef8aaadab90383"
assert_contains "${devcontainer_dir}/Dockerfile" "264238bc71dc85e2272ccde8e4a51deaff025e99"
assert_contains "${devcontainer_dir}/Dockerfile" "libcgal-dev"
assert_contains "${devcontainer_dir}/Dockerfile" "libpcl-dev"
assert_contains "${devcontainer_dir}/Dockerfile" "libopencv-dev"

assert_contains "${devcontainer_dir}/post-create.sh" "/home/vscode/r3live_ws"
assert_contains "${devcontainer_dir}/post-create.sh" "/opt/livox_ws/devel/setup.bash"
assert_contains "${devcontainer_dir}/post-create.sh" "/data/output"
assert_contains "${devcontainer_dir}/post-create.sh" "catkin_make"

assert_contains "${repo_root}/README.md" "Rebuild and Reopen in Container"
assert_contains "${repo_root}/README.md" "~/r3live_data"
assert_contains "${repo_root}/README.md" "roslaunch r3live r3live_bag.launch"

printf 'Dev Container contract checks passed.\n'
