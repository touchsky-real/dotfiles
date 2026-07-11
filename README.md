## Dotfiles

本仓库保存当前机器的常用配置：

- PowerShell profile
- Git config
- VS Code settings
- Alacritty config
- Scoop apps/buckets
- winget packages
- WSL config
- WSL `.zshrc`
- AdGuard Browser Extension settings
- Zashboard settings

## 同步本机配置到仓库

PowerShell profile：

```
Copy-Item $PROFILE powershell/Microsoft.PowerShell_profile.ps1
```

Git：

```
Copy-Item $HOME\.gitconfig git/.gitconfig
```

VS Code：

```
Copy-Item "$env:APPDATA\Code\User\settings.json" vscode/settings.json
```

Scoop：

```
scoop export | Set-Content scoop/apps.json
scoop bucket list | Select-Object -ExpandProperty Name | Set-Content scoop/buckets.txt
```

winget：

```
New-Item -ItemType Directory -Path winget -Force
winget export --output winget/packages.json --accept-source-agreements
```

WSL：

```
Copy-Item "$HOME\.wslconfig" wsl/.wslconfig
wsl bash -lc 'cat ~/.zshrc' | Set-Content wsl/.zshrc
```

AdGuard Browser Extension：

```
Copy-Item "<导出的 adg_ext_settings*.json>" adguard/extension-settings.json
```

Zashboard：

```
Copy-Item "<导出的 zashboard-settings*.json>" zashboard/zashboard-settings.json
```

## 恢复到本机

先看会执行什么：

```
.\install.ps1 -DryRun
```

恢复配置文件：

```
.\install.ps1
```

PowerShell profile 默认优先写入：

```
F:\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

也可以手动指定：

```
.\install.ps1 -PowerShellProfilePath "F:\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
```

恢复配置文件并安装 Scoop bucket/app：

```
.\install.ps1 -InstallScoopApps
```

恢复配置文件并安装 winget package：

```
.\install.ps1 -InstallWingetApps
```

同时恢复 Scoop 和 winget：

```
.\install.ps1 -InstallScoopApps -InstallWingetApps
```

默认会把目标文件备份到：

```
$HOME\.dotfiles-backup
```

如果不想备份：

```
.\install.ps1 -NoBackup
```

在 WSL/Linux 里恢复 shell 配置：

```
bash install.sh
```

AdGuard Browser Extension 和 Zashboard 需要在各自界面中手动导入：

```
adguard/extension-settings.json
zashboard/zashboard-settings.json
```
