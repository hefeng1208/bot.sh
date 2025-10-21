#!/bin/bash

# --- 0. 预检查和安装 Homebrew ---
echo "--- 1. 检查和安装 Homebrew ---"
if ! command -v brew > /dev/null; then
    echo "未检测到 Homebrew，正在安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # 确保 Homebrew PATH 生效，以便后续命令使用
    # 检查 Homebrew 的安装路径 (Apple Silicon 或 Intel)
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    else
        export PATH="/usr/local/bin:$PATH"
    fi
else
    echo "Homebrew 已安装，正在更新..."
    brew update
fi

# --- 1. 安装基础工具：iTerm2, Shell, Utilities, Env Tools ---
echo "--- 2. 安装 iTerm2, fish, rg, fzf, bat, git, volta, pyenv lsd tree tig---"

# 安装 iTerm2 (Cask) 和核心工具
brew install --cask iterm2
brew install fish ripgrep fzf bat git pyenv pyenv-virtualenv volta lsd tree tig

# 将 fish 添加到系统已知 shell 列表
FISH_PATH=$(brew --prefix)/bin/fish
if ! grep -q "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells
    echo "已将 fish ($FISH_PATH) 添加到 /etc/shells"
fi

# 切换默认 shell 到 fish (需要输入密码)
chsh -s "$FISH_PATH"
echo "✅ 默认 Shell 已切换为 fish。新的终端会话将使用 fish。"

echo "字体安装：建议安装 Nerd Font 以获得更好的终端显示效果。"
# 安装 FiraCode Nerd Font
#brew install --cask font-fira-code-nerd-font

# 安装 Meslo Nerd Font
 brew install --cask font-meslo-lg-nerd-font
echo "✅ 字体安装完成。请在 iTerm2 设置中选择该字体以获得最佳显示效果。"

# --- 2. 配置 fish shell (使用 fish 语法) ---
echo "--- 3. 配置 fish shell (config.fish) 和 ripgrep 配置 ---"

CONFIG_FILE="$HOME/.config/fish/config.fish"
FISH_FUNCTIONS_DIR="$HOME/.config/fish/functions"
RIPGREP_RC="$HOME/.ripgreprc"
HE_FENG_DIR="$HOME/Documents/hefeng"
JD_DIR="$HOME/Documents/jingdong"

# 创建工作目录
mkdir -p "$HE_FENG_DIR"
mkdir -p "$JD_DIR"

# 创建和配置 ripgrep 配置文件
echo "创建 ripgrep 配置文件..."
cat << 'EOF' > "$RIPGREP_RC"
# 智能大小写匹配（除非包含大写字母，否则忽略大小写）
--smart-case

# 默认搜索隐藏文件
--hidden

# 忽略常见的目录和文件
--glob=!.git/*
--glob=!node_modules/*
--glob=!vendor/*
--glob=!.DS_Store
--glob=!*.lock
--glob=!dist/*
--glob=!build/*

# 跟随符号链接
--follow

# 显示行号
--line-number

# 设置最大列宽，避免输出过宽
--max-columns=150
--max-columns-preview

# 搜索二进制文件时显示匹配行
--binary
EOF
echo "✅ ripgrep 配置文件创建完成"


# 确保函数目录存在
mkdir -p "$FISH_FUNCTIONS_DIR"

# 在 Bash 中设置 RIPGREP_CONFIG_PATH，但 fish 会在 config.fish 中设置
# set -x RIPGREP_CONFIG_PATH ~/.ripgreprc

# 确保 config.fish 文件存在
touch "$CONFIG_FILE"

# 移除旧配置以避免重复（兼容 macOS 和 Linux 的 sed 语法）
if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' '/^# --- START_CUSTOM_SETUP ---/,/^# --- END_CUSTOM_SETUP ---/d' "$CONFIG_FILE"
else
    sed -i '/^# --- START_CUSTOM_SETUP ---/,/^# --- END_CUSTOM_SETUP ---/d' "$CONFIG_FILE"
fi

# 写入新的配置内容
cat << EOF >> "$CONFIG_FILE"

# --- START_CUSTOM_SETUP ---

#=============================1. 核心工具安装 (rg, fzf, bat)====================================
# Fisher 包管理器
if not command -v fisher > /dev/null
    curl -sL https://git.io/fisher | source
end
fisher install jorgebucaran/fisher # 确保 fisher 本身已安装

# 别名和实用工具
alias ls='lsd'
alias cat='bat --paging=never'
alias gitg="open https://github.com/"
alias jj="cd $HOME/Documents/jingdong"
alias jf="cd $HOME/Documents/hefeng"
alias jja="cd $HOME/Documents/jingdong/ai"
alias pn='pnpm'
alias np='pnpm'

# fzf 键绑定
fzf --fish | source

#=============================2. rg + fzf + bat 集成函数 (rgl)====================================

# FZF 默认选项：使用 bat 预览文件内容
set -gx FZF_CTRL_T_OPTS "
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
"

# 设置 ripgrep 配置文件路径
set -gx RIPGREP_CONFIG_PATH \$HOME/.ripgreprc
# fzf 与 ripgrep/bat 的集成函数
# rgl: Ripgrep Live - 模糊搜索文件内容并预览
function rgl --description "Ripgrep Live Search (rg + fzf + bat)"
    # 使用 ripgrep (rg) 搜索内容，并通过 fzf 交互式过滤，用 bat 预览
    rg --color=always --line-number --no-heading --smart-case --hidden $argv |
        fzf \
            --ansi \
            --scheme=path \
            --delimiter : \
            --tiebreak=index \
            --preview 'bat --color=always --style=numbers,changes --highlight-line {2} {1}' \
            --preview-window 'up,60%,border-bottom,+{2}+3/3' \
            --bind "enter:execute(nano {1} +{2})" \
            --bind "ctrl-y:execute-silent(echo {1}:{2} | tr -d '\n' | pbcopy)"
end

#================================3. pyenv 配置 (Python 版本管理)==================================
set -Ux PYENV_ROOT \$HOME/.pyenv
fish_add_path \$PYENV_ROOT/bin
pyenv init - | source
status --is-interactive; and pyenv virtualenv-init - | source # pyenv-virtualenv 自动激活

#================================4. Volta 配置 (Node.js 版本管理) ================================
# Volta 会自动设置 PATH，这里是确保在 fish 中能正确加载
set -gx VOLTA_HOME \$HOME/.volta
fish_add_path \$VOLTA_HOME/bin

#=============================5. Volta 安装 Node.js 和 pnpm =====================================

# 由于 chsh -s fish 已经执行，我们需要一个新的 shell 才能使用 fish
# 这里通过 exec fish 启动一个新的 fish shell 来执行后续的 Volta 命令
echo "正在启动一个新的 fish shell 来执行 Volta 安装..."

# 使用 fish 命令来执行，确保环境变量正确
# 注意：Volta安装需要依赖Node版本
fish -c "
    echo '使用 volta 安装 Node.js latest...'
    volta install node@latest

    echo '使用 volta 安装 pnpm latest...'
    volta install pnpm@latest

    echo '✅ Node.js 和 pnpm 已通过 Volta 安装完成。'
"

#==============================6. git 基础配置 ===================================================

# Git 基础配置 (可选，可根据需要修改)
git config --global init.defaultBranch main
# 默认使用 bat 作为 diff 工具
git config --global core.pager "bat --paging=never"
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.cm commit
git config --global alias.df diff
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
git config --global alias.pl "pull --rebase"

echo "创建目录特定的 git 配置文件..."

# 创建 hefeng.inc Git 配置文件
cat << 'HEFENG_GIT_CONFIG' > "$HE_FENG_DIR/hefeng.inc"
[user]
  name = hefeng1208
  email = frontway26@163.com
[core]
  editor = nano
[pull]
  rebase = true
HEFENG_GIT_CONFIG

# 创建 jingdong.inc Git 配置文件
cat << 'JINGDONG_GIT_CONFIG' > "$JD_DIR/jingdong.inc"
[user]
  name = hefeng26
  email = hefeng3@jd.com
[core]
  editor = nano
[pull]
  rebase = true
JINGDONG_GIT_CONFIG

# 配置 Git 在这些目录下自动使用对应的配置文件
git config --global includeIf."gitdir:$HE_FENG_DIR/".path "$HE_FENG_DIR/hefeng.inc"
git config --global includeIf."gitdir:$JD_DIR/".path "$JD_DIR/jingdong.inc"

echo "✅ 目录特定的 git 配置文件创建完成"

#==============================7. 生成SSH密钥对 =================================================

echo "正在生成SSH密钥对..."

# 确保.ssh目录存在
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# 生成hefeng个人账号的SSH密钥
echo "生成hefeng个人账号SSH密钥..."
ssh-keygen -t rsa -b 4096 -C "frontway26@163.com" -f "$HOME/.ssh/id_rsa_hefeng" -N "" > /dev/null

# 生成京东工作账号的SSH密钥
echo "生成京东工作账号SSH密钥..."
ssh-keygen -t rsa -b 4096 -C "hefeng3@jd.com" -f "$HOME/.ssh/id_rsa_jd" -N "" > /dev/null

# 创建或更新SSH配置文件
cat << 'EOF' > "$HOME/.ssh/config"
# hefeng 个人GitHub账号
Host github.com
    User frontway26@163.com
    #HostName ssh.github.com
    # IdentityFile ~/.ssh/id_rsa_hefeng
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# 京东工作账号
Host coding.jd.com
    HostName coding.jd.com
    IdentityFile ~/.ssh/id_rsa_jd
    User hefeng3@jd.com
# Gitee 配置
Host gitee.com
    HostName gitee.com
    User 3028213607
EOF
echo "✅ SSH 配置文件 ($HOME/.ssh/config) 创建完成"

# 显示公钥以便复制
echo "================================================="
echo "hefeng 个人账号的 SSH 公钥 (添加到 GitHub):"
echo "================================================="
cat "$HOME/.ssh/id_rsa_hefeng.pub"
echo ""
echo "================================================="
echo "京东工作账号的 SSH 公钥 (添加到企业 GitHub/Gitee/JD):"
echo "================================================="
cat "$HOME/.ssh/id_rsa_jd.pub"
echo "================================================="
echo "SSH 密钥已生成。请将上面的公钥复制到相应的账户。"
echo "hefeng 个人项目克隆格式: git clone git@github.com-hefeng:username/repo.git"
echo "京东项目克隆格式: git clone git@coding.jd.com:username/repo.git"

# --- 6. 提示和下一步操作 ---
echo "--- 6. 后续步骤和提示 ---"
echo "================================================="
echo "重要：以下步骤必须在新启动的 iTerm2 中运行！"
echo "================================================="
echo "1. iTerm2 配置：请手动打开 iTerm2 -> Settings (Cmd + ,) -> Profiles -> Default -> General -> Command，选择 'Custom Shell' 并输入: $FISH_PATH"
echo "2. 启动新的 iTerm2 窗口 (此时应使用 fish shell)"
echo "3. Node.js 和 pnpm 安装（在新 fish shell 中执行）："
echo "   \$ volta install node@latest"
echo "   \$ volta install pnpm@latest"
echo "4. Python 使用：在新 fish shell 中，运行 'pyenv install 3.10.12' 安装一个 Python 版本。"
echo "5. 字体：为了正确显示某些符号，建议安装 Nerd Font 并在 iTerm2 中设置。"

echo ""
echo "配置脚本执行完毕。请执行提示中的后续操作。"
