param([int]$N = 50000)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$nasm = 'D:\asm-tools\nasm-2.16.03\nasm.exe'
& $nasm -f bin -l (Join-Path $root 'lvl_tree.lst') -o (Join-Path $root 'lvl_tree.bin') (Join-Path $root 'lvl_tree.asm')
if ($LASTEXITCODE -ne 0) { throw 'nasm failed' }
$blob = [System.IO.File]::ReadAllBytes((Join-Path $root 'lvl_tree.bin'))
$offs = @{}
$pending = $null
foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $root 'lvl_tree.lst'))) {
  if ($line -match '^\s*\d+\s+([A-Za-z_][A-Za-z0-9_.]*):\s*$') { $pending = $Matches[1]; continue }
  if ($pending -and $line -match '^\s*\d+\s+([0-9A-F]{8})\s') { $offs[$pending] = [Convert]::ToInt32($Matches[1], 16); $pending = $null }
}
"lvl_equiv @ {0}, blob {1}" -f $offs['lvl_equiv'], $blob.Length
$cs = [System.IO.File]::ReadAllText((Join-Path $root 'harness.cs.txt'), [System.Text.Encoding]::UTF8)
$cp = New-Object System.CodeDom.Compiler.CompilerParameters
$cp.GenerateInMemory = $true
@('System.dll','System.Core.dll','mscorlib.dll') | ForEach-Object { [void]$cp.ReferencedAssemblies.Add($_) }
Add-Type -TypeDefinition $cs -CompilerParameters $cp -Language CSharp
[LevelTest]::Run($blob, $offs['lvl_equiv'], (Join-Path $root 'pairs.txt'), (Join-Path $root 'asm_out.txt'), $N)
