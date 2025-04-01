#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/gensyn-ai.sh"

# 安装gensyn-ai节点函数
function install_gensyn_ai_node() {
    # 更新系统
    sudo apt-get update && sudo apt-get upgrade -y

    # 安装指定的软件包
    sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev python3 python3-pip

    # 安装 Yarn
    echo "正在安装 Yarn..."
    curl -o- -L https://yarnpkg.com/install.sh | sh
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    source ~/.bashrc
    echo "Yarn 安装完成"
    
    # 检测 Docker 是否安装
    if ! command -v docker &> /dev/null
    then
        echo "Docker 未安装，正在安装 Docker..."
        # 安装 Docker
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce
        echo "Docker 安装完成"
    else
        echo "Docker 已安装"
    fi

    # 克隆 GitHub 仓库并切换到该目录
    git clone https://github.com/gensyn-ai/rl-swarm/
    cd rl-swarm

    # 创建并激活 Python 虚拟环境
    python3 -m venv .venv
    source .venv/bin/activate

    # 在 screen 会话中安装并运行 swarm
    screen -S swarm -d -m bash -c "./run_rl_swarm.sh"
    echo "Swarm 已通过 screen 在后台启动，使用 'screen -r swarm' 进入后台进行下一步操作"

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 查看Rl Swarm日志函数
function view_rl_swarm_logs() {
    cd /root/rl-swarm && docker-compose logs -f swarm_node

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 查看Web UI日志函数
function view_web_ui_logs() {
    cd /root/rl-swarm && docker-compose logs -f fastapi

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 查看Telemetry日志函数
function view_telemetry_logs() {
    cd /root/rl-swarm && docker-compose logs -f otel-collector

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 Ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 安装gensyn-ai节点"
        echo "2. 查看Rl Swarm日志"
        echo "3. 查看Web UI日志"
        echo "4. 查看Telemetry日志"
        echo "5. 退出"
        read -p "请输入选项 [1-5]: " choice
        case $choice in
            1)
                install_gensyn_ai_node
                ;;
            2)
                view_rl_swarm_logs
                ;;
            3)
                view_web_ui_logs
                ;;
            4)
                view_telemetry_logs
                ;;
            5)
                exit 0
                ;;
            *)
                echo "无效的选项，请重试..."
                sleep 2
                ;;
        esac
    done
}

# 运行主菜单
main_menu

