#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/gensyn-ai.sh"

# 安装gensyn-ai节点函数
function install_gensyn_ai_node() {
    # 更新系统
    sudo apt-get update && sudo apt-get upgrade -y

    # 安装指定的软件包
    sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev python3 python3-pip

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

    # 备份现有的 docker-compose.yaml 文件
    mv docker-compose.yaml docker-compose.yaml.old

    # 提示用户选择是否有显卡
    read -p "您的系统是否有显卡？(y/n): " has_gpu

    # 根据用户选择创建新的 docker-compose.yaml 文件
    if [ "$has_gpu" == "y" ]; then
        cat <<EOL > docker-compose.yaml
version: '3'

services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.120.0
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
      - "55679:55679"  # Prometheus metrics (optional)
    environment:
      - OTEL_LOG_LEVEL=DEBUG

  swarm_node:
    image: europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.2
    command: ./run_hivemind_docker.sh
    runtime: nvidia  # Enables GPU support; remove if no GPU is available
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - PEER_MULTI_ADDRS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
      - HOST_MULTI_ADDRS=/ip4/0.0.0.0/tcp/38331
    ports:
      - "38331:38331"  # Exposes the swarm node's P2P port
    depends_on:
      - otel-collector

  fastapi:
    build:
      context: .
      dockerfile: Dockerfile.webserver
    environment:
      - OTEL_SERVICE_NAME=rlswarm-fastapi
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - INITIAL_PEERS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
    ports:
      - "8080:8000"  # Maps port 8080 on the host to 8000 in the container
    depends_on:
      - otel-collector
      - swarm_node
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/healthz"]
      interval: 30s
      retries: 3
EOL
    else
        cat <<EOL > docker-compose.yaml
version: '3'

services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.120.0
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
      - "55679:55679"  # Prometheus metrics (optional)
    environment:
      - OTEL_LOG_LEVEL=DEBUG

  swarm_node:
    image: europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.2
    command: ./run_hivemind_docker.sh
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - PEER_MULTI_ADDRS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
      - HOST_MULTI_ADDRS=/ip4/0.0.0.0/tcp/38331
    ports:
      - "38331:38331"  # Exposes the swarm node's P2P port
    depends_on:
      - otel-collector

  fastapi:
    build:
      context: .
      dockerfile: Dockerfile.webserver
    environment:
      - OTEL_SERVICE_NAME=rlswarm-fastapi
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - INITIAL_PEERS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
    ports:
      - "8080:8000"  # Maps port 8080 on the host to 8000 in the container
    depends_on:
      - otel-collector
      - swarm_node
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/healthz"]
      interval: 30s
      retries: 3
EOL
    fi

    # 执行 docker compose up --build -d 并显示日志
    docker compose up --build -d && docker compose logs -f
}

# 查看Rl Swarm日志函数
function view_rl_swarm_logs() {
    docker-compose logs -f swarm_node
}

# 查看Web UI日志函数
function view_web_ui_logs() {
    docker-compose logs -f fastapi
}

# 查看Telemetry日志函数
function view_telemetry_logs() {
    docker-compose logs -f otel-collector
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

