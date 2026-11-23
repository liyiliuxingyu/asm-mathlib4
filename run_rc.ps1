param([long]$Limit = 10000000)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$nasm = 'D:\asm-tools\nasm-2.16.03\nasm.exe'
& $nasm -f bin -l (Join-Path $root 'lean_rc.lst') -o (Join-Path $root 'lean_rc.bin') (Join-Path $root 'lean_rc.asm')
if ($LASTEXITCODE -ne 0) { throw 'nasm failed' }
$blob = [System.IO.File]::ReadAllBytes((Join-Path $root 'lean_rc.bin'))
$offs = @{}
$pending = $null
foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $root 'lean_rc.lst'))) {
  if ($line -match '^\s*\d+\s+([A-Za-z_][A-Za-z0-9_.]*):\s*$') { $pending = $Matches[1]; continue }
  if ($pending -and $line -match '^\s*\d+\s+([0-9A-F]{8})\s') { $offs[$pending] = [Convert]::ToInt32($Matches[1], 16); $pending = $null }
}
$incOff = $offs['lean_inc_asm']; $decOff = $offs['lean_dec_asm']
"lean_inc_asm @ {0}, lean_dec_asm @ {1}, total {2} bytes" -f $incOff, $decOff, $blob.Length
$inc = [byte[]]$blob[$incOff..($decOff - 1)]
$dec = [byte[]]$blob[$decOff..($blob.Length - 1)]
"inc: {0}" -f (($inc | ForEach-Object { $_.ToString('X2') }) -join ' ')
"dec: {0}" -f (($dec | ForEach-Object { $_.ToString('X2') }) -join ' ')
$cs = [System.IO.File]::ReadAllText((Join-Path $root 'rc_harness.cs.txt'), [System.Text.Encoding]::UTF8)
$cp = New-Object System.CodeDom.Compiler.CompilerParameters
$cp.CompilerOptions = '/unsafe'
$cp.GenerateInMemory = $true
@('System.dll','System.Core.dll','mscorlib.dll') | ForEach-Object { [void]$cp.ReferencedAssemblies.Add($_) }
Add-Type -TypeDefinition $cs -CompilerParameters $cp -Language CSharp
[RcHarness]::Sweep($inc, $dec, $Limit)
