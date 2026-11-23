param([int]$N = 200000)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$nasm = 'D:\asm-tools\nasm-2.16.03\nasm.exe'
& $nasm -f bin -l (Join-Path $root 'gcd.lst') -o (Join-Path $root 'gcd.bin') (Join-Path $root 'gcd.asm')
if ($LASTEXITCODE -ne 0) { throw "nasm failed with $LASTEXITCODE" }
$code = [System.IO.File]::ReadAllBytes((Join-Path $root 'gcd.bin'))
"gcd.bin: $($code.Length) bytes  (" + (($code | ForEach-Object { $_.ToString('X2') }) -join ' ') + ")"
$cs = [System.IO.File]::ReadAllText((Join-Path $root 'harness.cs.txt'), [System.Text.Encoding]::UTF8)
Add-Type -TypeDefinition $cs -Language CSharp -ReferencedAssemblies 'System.Numerics'
[AsmHarness]::Run($code, $N)
