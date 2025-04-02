#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/gensyn-ai.sh"

# 安装 gensyn-ai 节点
function install_gensyn_ai_node() {
    # 更新系统并安装必要软件包
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf \
        tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip \
        python3 python3-pip python3.10-venv xdg-utils

    # **安装 nvm**
    if ! command -v nvm &> /dev/null; then
        echo "正在安装 NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
        source ~/.bashrc
        source ~/.profile
        echo "NVM 安装完成"
    else
        echo "NVM 已安装"
    fi

    # **使用 nvm 安装 Node.js 18**
    source ~/.bashrc
    source ~/.profile
    nvm install 18
    nvm use 18
    nvm alias default 18

    # 确保 Node.js 版本正确
    echo "当前 Node.js 版本：$(node -v)"
    echo "当前 npm 版本：$(npm -v)"

    # **安装 Yarn**
    echo "正在安装 Yarn..."
    npm install -g yarn
    echo "Yarn 安装完成"

    # 检测 Docker 是否安装
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，正在安装 Docker..."
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
        echo "Docker 安装完成，请重新登录以应用 Docker 权限"
    else
        echo "Docker 已安装"
    fi

    # 克隆 GitHub 仓库并进入目录
    git clone https://github.com/gensyn-ai/rl-swarm/ || true
    cd rl-swarm || exit

    # **修改 run_rl_swarm.sh**
    if [ -f "run_rl_swarm.sh" ]; then
        sed -i 's|open http://localhost:3000|xdg-open http://localhost:3000 2>/dev/null || echo "Please open http://localhost:3000 in your browser"|' run_rl_swarm.sh
        echo "已修改 run_rl_swarm.sh"
    else
        echo "警告: run_rl_swarm.sh 文件未找到，无法修改"
    fi

    # 创建 Python 虚拟环境
    python3 -m venv .venv
    source .venv/bin/activate

    # 修复 protobuf 版本冲突（强制降级）
    echo "正在修复 protobuf 版本冲突..."
    pip install "protobuf>=3.12.2,<5.28.0" --force-reinstall
    echo "protobuf 版本已更新"

    # **安装 Node.js 依赖**
    rm -rf node_modules package-lock.json yarn.lock
    yarn install

    # 检测 CPU 核心数并设置线程
    CPU_CORES=$(nproc)
    DEFAULT_THREADS=$((CPU_CORES / 2))
    echo "\n检测到你有 $CPU_CORES 个 CPU 核心。"
    read -p "请输入线程数（建议：$DEFAULT_THREADS）: " USER_THREADS
    export OMP_NUM_THREADS=${USER_THREADS:-$DEFAULT_THREADS}
    echo "已设置 OMP_NUM_THREADS=$OMP_NUM_THREADS"

    # 使用 screen 启动 RL Swarm
    if [ -f "./run_rl_swarm.sh" ]; then
        chmod +x run_rl_swarm.sh
        screen -S swarm -d -m bash -c "./run_rl_swarm.sh"
        echo "Swarm 已在后台运行。使用 'screen -r swarm' 进入后台进行下一步操作。"
    else
        screen -S swarm -d -m bash -c "python main.py"
        echo "未找到 run_rl_swarm.sh，已使用 Python 方式运行 Swarm。"
        echo "Swarm 已在后台运行。使用 'screen -r swarm' 进入后台进行下一步操作。"
    fi

    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 删除 gensyn-ai 节点
function delete_gensyn_ai_node() {
    echo "正在删除 gensyn-ai 节点..."
    sudo systemctl stop docker
    sudo rm -rf $HOME/rl-swarm
    sudo docker system prune -a -f
    sudo systemctl start docker
    echo "gensyn-ai 节点已删除，Docker 已清理。"
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 日志查看函数
function view_logs() {
    case $1 in
        "swarm") cd /root/rl-swarm && docker-compose logs -f swarm_node ;;
        "web") cd /root/rl-swarm && docker-compose logs -f fastapi ;;
        "telemetry") cd /root/rl-swarm && docker-compose logs -f otel-collector ;;
    esac
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 主菜单
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按 Ctrl + C 退出"
        echo "请选择操作:"
        echo "1. 安装 gensyn-ai 节点"
        echo "2. 查看 RL Swarm 日志"
        echo "3. 查看 Web UI 日志"
        echo "4. 查看 Telemetry 日志"
        echo "5. 删除 gensyn-ai 节点"
        echo "6. 退出"
        read -p "请输入选项 [1-6]: " choice
        case $choice in
            1) install_gensyn_ai_node ;;
            2) view_logs "swarm" ;;
            3) view_logs "web" ;;
            4) view_logs "telemetry" ;;
            5) delete_gensyn_ai_node ;;
            6) exit 0 ;;
            *) echo "无效选项，请重试..."; sleep 2 ;;
        esac
    done
}

# 运行主菜单
main_menu
