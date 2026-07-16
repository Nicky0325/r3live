FROM osrf/ros:noetic-desktop-full-focal

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG LIVOX_SDK_REF=7cf759a760ac674b7032c48b46ef8aaadab90383
ARG LIVOX_ROS_DRIVER_REF=264238bc71dc85e2272ccde8e4a51deaff025e99

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        git \
        libapr1-dev \
        libboost-all-dev \
        libcgal-dev \
        libeigen3-dev \
        libgl1-mesa-dri \
        libopencv-dev \
        libpcl-dev \
        mesa-utils \
        pcl-tools \
        pkg-config \
        ros-noetic-cv-bridge \
        ros-noetic-image-transport \
        ros-noetic-message-filters \
        ros-noetic-pcl-conversions \
        ros-noetic-pcl-ros \
        ros-noetic-tf \
        sudo \
        xauth \
    && rm -rf /var/lib/apt/lists/*

RUN if ! getent group "${USER_GID}" >/dev/null; then \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi \
    && if id -u "${USERNAME}" >/dev/null 2>&1; then \
        usermod --uid "${USER_UID}" --gid "${USER_GID}" "${USERNAME}"; \
    else \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
    fi \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}" \
    && mkdir -p "/home/${USERNAME}" \
    && chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"

RUN git clone https://github.com/Livox-SDK/Livox-SDK.git /tmp/Livox-SDK \
    && git -C /tmp/Livox-SDK checkout "${LIVOX_SDK_REF}" \
    && cmake -S /tmp/Livox-SDK -B /tmp/Livox-SDK/build -DCMAKE_BUILD_TYPE=Release \
    && jobs="$(nproc)" \
    && if (( jobs > 4 )); then jobs=4; fi \
    && cmake --build /tmp/Livox-SDK/build --parallel "${jobs}" \
    && cmake --install /tmp/Livox-SDK/build \
    && rm -rf /tmp/Livox-SDK

RUN mkdir -p /opt/livox_ws/src \
    && git clone https://github.com/ziv-lin/livox_ros_driver_for_R2LIVE.git \
        /opt/livox_ws/src/livox_ros_driver_for_R2LIVE \
    && git -C /opt/livox_ws/src/livox_ros_driver_for_R2LIVE checkout "${LIVOX_ROS_DRIVER_REF}" \
    && source /opt/ros/noetic/setup.bash \
    && cd /opt/livox_ws \
    && jobs="$(nproc)" \
    && if (( jobs > 4 )); then jobs=4; fi \
    && catkin_make -DCMAKE_BUILD_TYPE=Release -j"${jobs}" \
    && rm -rf /opt/livox_ws/build

ENV DEBIAN_FRONTEND=dialog

WORKDIR /workspaces/r3live

