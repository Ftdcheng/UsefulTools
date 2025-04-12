#!/bin/bash
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

