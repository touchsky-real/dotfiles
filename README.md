## 1. 先迁移最核心配置

比如：

```
Copy-Item $PROFILE powershell/Microsoft.PowerShell_profile.ps1
Copy-Item $HOME\.gitconfig git/.gitconfig
```

------

## 2. 写 install.ps1

后面一键恢复环境。