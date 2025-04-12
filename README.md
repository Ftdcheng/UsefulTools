# UsefulTools
## `docker_install.sh`
docker + nvidia container toolkit 一键安装脚本, 目前是Ubuntu专用
接受一个参数，nvidia container tookit deb包的目录，如果你不能通过apt直接下载deb的话，你可以通过其他方式获取deb包，然后放在一个目录里，脚本会安装目录里的所有deb。

> 你可以在网络正常的机器上下载deb，命令如下：
```bash
apt download nvidia-container-toolkit libnvidia-container1 nvidia-container-toolkit-base libnvidia-container-tools
```
这样你需要的所有包都会下载到当前目录，把这些包复制到目标目录。

## `log.sh`
彩色LOG
