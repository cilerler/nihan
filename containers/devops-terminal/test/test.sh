#!/usr/bin/env bash
cd $(dirname "$0")

# -- Utility functions --
if [ -z $HOME ]; then
    HOME="/root"
fi

FAILED=()

check() {
    LABEL=$1
    shift
    echo -e "\n🧪  Testing $LABEL: $@"
    if $@; then 
        echo "🏆  Passed!"
    else
        echo "💥  $LABEL check failed."
        FAILED+=("$LABEL")
    fi
}

checkMultiple() {
    PASSED=0
    LABEL="$1"
    shift; MINIMUMPASSED=$1
    shift; EXPRESSION="$1"
    while [ "$EXPRESSION" != "" ]; do
        if $EXPRESSION; then ((PASSED++)); fi
        shift; EXPRESSION=$1
    done
    check "$LABEL" [ $PASSED -ge $MINIMUMPASSED ]
}

checkExtension() {
    checkMultiple "$1" 1 "[ -d ""$HOME/.vscode-server/extensions/$1*"" ]" "[ -d ""$HOME/.vscode-server-insiders/extensions/$1*"" ]" "[ -d ""$HOME/.vscode-test-server/extensions/$1*"" ]"
}

# -- Actual tests - add more here --
checkMultiple "vscode-server" 1 "[ -d ""$HOME/.vscode-server/bin"" ]" "[ -d ""$HOME/.vscode-server-insiders/bin"" ]" "[ -d ""$HOME/.vscode-test-server/bin"" ]"
check "non-root-user" "id vscode"
check "/home/vscode" [ -d "/home/vscode" ]
check "sudo" sudo -u vscode echo "sudo works."
check "git" git --version
check "command-line-tools" which top ip

checkExtension "ms-azuretools.vscode-docker"
checkExtension "ms-kubernetes-tools.vscode-kubernetes-tools"
check "docker" docker ps -a
check "docker-compose" docker-compose --version
check "kubernetes-config" [ -d "$HOME/.kube" ]
check "kubectl" kubectl version --client
check "helm" helm version --client

checkExtension "ms-vscode.powershell"
check "powershell" pwsh ./powershell/hello.ps1

checkExtension "ms-vscode.vscode-typescript-tslint-plugin"
check "node" "node --version"
check "npm" npm --prefix ./typescript install
check "tslint" "tslint typescript/server.ts"
check "typescript" npm --prefix ./typescript run compile
check "test" npm --prefix ./typescript run test

checkExtension "ms-vscode.csharp"
check "dotnet" "dotnet --version"

# -- Report results --
if [ ${#FAILED[@]} -ne 0 ]; then
    echo -e "\n💥  Failed tests: ${FAILED[@]}"
    exit 1
else 
    echo -e "\n💯  All passed!"
    exit 0
fi