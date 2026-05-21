function cao {
    conda activate otdr
}

$null = scoop-search --hook | Invoke-Expression

Invoke-Expression (&starship init powershell)

# 删除前一个词
Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardKillWord

# 删除后一个词
Set-PSReadLineKeyHandler -Key Alt+d -Function KillWord

# 跳词移动
Set-PSReadLineKeyHandler -Key Alt+b -Function BackwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ForwardWord
