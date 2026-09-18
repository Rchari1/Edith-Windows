# Edith status line for Claude Code, on Windows.
#
# Reads the session JSON Claude Code puts on stdin, asks the local Edith server
# what happened in *this* session, and prints one line above the footer.
#
# PowerShell rather than a batch file because Windows ships it and it parses
# JSON natively; batch cannot read the payload Claude sends. If Edith is not
# running it prints a dim marker rather than an error, because a status line
# that shouts about its own failure is worse than one that quietly says
# "offline".
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$esc = [char]27
$cyan = "$esc[38;5;117m"; $dim = "$esc[38;5;240m"; $text = "$esc[38;5;250m"; $reset = "$esc[0m"
$mark = [char]0x25C8

$sessionId = ''
try {
  $raw = [Console]::In.ReadToEnd()
  if ($raw) { $sessionId = ([string](($raw | ConvertFrom-Json).session_id)) }
} catch { $sessionId = '' }

$path = if ($sessionId) { "/session/$sessionId" } else { '/session/unknown' }
$data = $null
foreach ($port in 4319, 4320, 4321, 4322) {
  try {
    $data = Invoke-RestMethod -Uri "http://127.0.0.1:$port$path" -TimeoutSec 1
    if ($data) { break }
  } catch { continue }
}

if (-not $data) {
  Write-Output "$dim$mark Edith offline$reset"
  exit 0
}

$notes = [int]$data.notes
$recalled = [int]$data.session.searches + [int]$data.session.reads
$saved = [int]$data.session.saves

$parts = @("$cyan$mark Edith$reset")
$parts += "$text$notes memor$(if ($notes -eq 1) { 'y' } else { 'ies' })$reset"
if ($recalled) { $parts += "$text$recalled recalled$reset" }
if ($saved) { $parts += "$text$saved formed$reset" }
if (-not $recalled -and -not $saved) { $parts += "$dim" + "idle$reset" }

Write-Output ($parts -join " $dim" + [char]0xB7 + "$reset ")
