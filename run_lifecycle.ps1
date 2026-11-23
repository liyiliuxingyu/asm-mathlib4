param([int]$Ops = 200000)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$nasm = 'D:\asm-tools\nasm-2.16.03\nasm.exe'
& $nasm -f bin -l (Join-Path $root 'lean_lifecycle.lst') -o (Join-Path $root 'lean_lifecycle.bin') (Join-Path $root 'lean_lifecycle.asm')
if ($LASTEXITCODE -ne 0) { throw 'nasm failed' }
$blob = [System.IO.File]::ReadAllBytes((Join-Path $root 'lean_lifecycle.bin'))
$offs = @{}
$pending = $null
foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $root 'lean_lifecycle.lst'))) {
  if ($line -match '^\s*\d+\s+([A-Za-z_][A-Za-z0-9_.]*):\s*$') { $pending = $Matches[1]; continue }
  if ($pending -and $line -match '^\s*\d+\s+([0-9A-F]{8})\s') { $offs[$pending] = [Convert]::ToInt32($Matches[1], 16); $pending = $null }
}
"offsets: inc={0} dec={1} cold={2}  blob={3} bytes" -f $offs['lean_inc_asm'], $offs['lean_dec_asm'], $offs['lean_dec_ref_cold_asm'], $blob.Length
$cs = [System.IO.File]::ReadAllText((Join-Path $root 'lifecycle_harness.cs.txt'), [System.Text.Encoding]::UTF8)
$cp = New-Object System.CodeDom.Compiler.CompilerParameters
$cp.GenerateInMemory = $true
@('System.dll','System.Core.dll','mscorlib.dll') | ForEach-Object { [void]$cp.ReferencedAssemblies.Add($_) }
Add-Type -TypeDefinition $cs -CompilerParameters $cp -Language CSharp
[Lifecycle]::Run($blob, $offs['lean_inc_asm'], $offs['lean_dec_asm'], $offs['lean_dec_ref_cold_asm'], $Ops)
