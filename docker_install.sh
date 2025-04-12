DOCKER_GPG_PREFIX=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu
GPG_URL=${DOCKER_GPG_PREFIX}/gpg 
GPG_FILE=/etc/apt/keyrings/docker.asc
NV_CON_TOOL_GPG_FILE=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
NV_CON_TOOL_APT_SRC=/etc/apt/sources.list.d/nvidia-container-toolkit.list
DEB_PATH=${1:-~/Downloads}

# log.sh - 彩色日志模块，适配 bash/zsh/sh 环境
# 时间戳（可选）
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

log_info() {
  echo -e "\033[36m[$(timestamp)] [INFO   ] $*\033[0m"
}

log_success() {
  echo -e "\033[32m[$(timestamp)] [SUCCESS] $*\033[0m"
}

log_warn() {
  echo -e "\033[33m[$(timestamp)] [WARN   ] $*\033[0m"
}

log_error() {
  echo -e "\033[31m[$(timestamp)] [ERROR  ] $*\033[0m" >&2
}

log_debug() {
  echo -e "\033[35m[$(timestamp)] [DEBUG  ] $*\033[0m"
}

log_fatal() {
  echo -e "\033[41;97m[$(timestamp)] [FATAL  ] $*\033[0m" >&2
  exit 1
}

log_progress() {
  local msg=$1
  echo -ne "\033[34m[....] $msg\033[0m\r"
  sleep 0.5
  echo -ne "\033[34m[→→→ ] $msg\033[0m\r"
  sleep 0.5
  echo -ne "\033[34m[ OK ] $msg\033[0m\n"
}

# 如果你需要日志重定向到文件
log_to_file() {
  local logfile="$1"
  exec > >(tee -a "$logfile") 2>&1
}

check_docker_exist() {
    if ! command -v docker &>/dev/null; then
        return 1
    fi
}
check_docker_running() {
    if ! docker info &>/dev/null; then
        return 1
    fi
    return 0
}

check_docker_group() {
    if groups $USER | grep -q '\bdocker\b'; then
        log_info "✅ 当前用户属于 docker 用户组"
    else
        log_warn "当前用户不在 docker 组，可能无法无 sudo 使用 docker"
        log_info "你可以运行：sudo usermod -aG docker $USER && newgrp docker"
    fi
}

install_docker() {
    if check_docker_exist; then
        log_info "✅ docker 已安装"
        return 0
    fi
    log_info "⬇️ 正在安装docker..."
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL $GPG_URL -o $GPG_FILE
    if [ -s "$GPG_FILE" ]; then
        log_info "✅ GPG 公钥成功下载并保存到 $GPG_FILE"
    else
        log_error "❌ GPG 文件为空，可能被代理或防火墙拦截了"
        exit 1
    fi
    sudo chmod a+r $GPG_FILE

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=$GPG_FILE] $DOCKER_GPG_PREFIX \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    if check_docker_exist; then
        log_success "✅ Docker安装成功"
        return 0
    else
        return 1
    fi
}

install_nvc_deb() {
    # 检查路径是否存在
    if [ ! -d "$DEB_PATH" ]; then
      log_error "目录 $DEB_PATH 不存在！"
      return 1
    fi

    log_info "开始遍历目录：$DEB_PATH"

    # 查找所有 .deb 文件（递归）
    deb_files=$(find "$DEB_PATH" -type f -name "*.deb")

    if [ -z "$deb_files" ]; then
      log_error "没有找到任何 .deb 文件"
      return 1
    fi

    # 遍历并安装
    for deb in $deb_files; do
      log info "安装 $deb ..."
      if sudo dpkg -i "$deb"; then
        log ok "安装成功：$deb"
      else
        log err "安装失败：$deb"
        return 1
      fi
    done

    log info "🎉 所有可用 .deb 安装任务完成"
    return 0
}

install_nvidia_container_toolkit() {
    if dpkg -s nvidia-container-toolkit &> /dev/null; then
        log_info "✅ NVIDIA Container Toolkit 已安装"
        return 0
    fi
    log_info "⬇️ 正在安装NVIDIA Container Toolkit..."
    if ! [ -s "$NV_CON_TOOL_GPG_FILE" ] || ! [ -s "$NV_CON_TOOL_APT_SRC" ]; then
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
          && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    fi
    if [ -s "$NV_CON_TOOL_GPG_FILE" ]; then
        log_info "✅ nvidia container toolkit GPG 公钥成功下载并保存到 $NV_CON_TOOL_GPG_FILE"
    else
        log_error "❌ nvidia container toolkit GPG 文件为空，可能被代理或防火墙拦截了"
        log_info "尝试使用本地deb安装..."
        if ! install_nvc_deb; then
            exit 1
        fi
    fi
    sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    if command -v nvidia-container-toolkit &> /dev/null;then
        log_success "✅ nvidia container toolkit 安装成功"
        exit 0
    else
        log_info "❌ nvidia container toolkit 安装失败"
        exit 1
    fi
}

check_execution() {
    if ! [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        return 0    
    else
        return 1
    fi
}

if check_execution; then
    install_docker
    install_nvidia_container_toolkit
    check_docker_group
fi
