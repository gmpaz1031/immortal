param([string]$FilePath)
$code = Get-Content -Raw $FilePath
$payload = @{ code = $code } | ConvertTo-Json
$res = Invoke-RestMethod -Uri "http://127.0.0.1:34875/exec" -Method Post -Body $payload -ContentType "application/json"
$id = $res.id

for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 200
    try {
        $result = Invoke-RestMethod -Uri "http://127.0.0.1:34875/result?id=$id"
        $result | ConvertTo-Json
        exit 0
    } catch {
        # continue waiting
    }
}
Write-Error "Timed out waiting for result"
exit 1
