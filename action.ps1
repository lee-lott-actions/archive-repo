function Set-RepositoryArchiveStatus {
	param(
		[string]$RepoName,
		[string]$Token,
		[string]$Owner
	)

	# Validate required inputs
	if ([string]::IsNullOrEmpty($RepoName) -or
		[string]::IsNullOrEmpty($Token) -or
		[string]::IsNullOrEmpty($Owner)) {

		Write-Host "Error: Missing required parameters"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: repo-name, token, and owner must be provided."
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		return
	}

	Write-Host "Attempting to archive repository $Owner/$RepoName"

	# Use MOCK_API if set, otherwise default to GitHub API
	$apiBaseUrl = $env:MOCK_API
	if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }

	$uri = "$apiBaseUrl/repos/$Owner/$RepoName"

	$headers = @{
		Authorization  = "Bearer $Token"
		Accept         = "application/vnd.github+json"
		"Content-Type" = "application/json"
		"User-Agent"   = "pwsh-action"
	}

	$body = @{ archived = $true } | ConvertTo-Json -Compress

	try {
		$response = Invoke-WebRequest -Uri $uri -Method Patch -Headers $headers -Body $body

		if ($response.StatusCode -ne 200) {
			$errorMsg = "Error: Failed to archive repository $Owner/$RepoName. HTTP Status: $($response.StatusCode)"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
			Write-Host $errorMsg
			return
		}

		$isArchived = $null
		try {
			if (-not [string]::IsNullOrEmpty($response.Content)) {
				$json = $response.Content | ConvertFrom-Json
				$isArchived = $json.archived
			}
		} catch {
			$isArchived = $null
		}

		$isArchived = ($isArchived -eq $true -or "$isArchived" -eq "true")

		if (-not $isArchived) {
			$errorMsg = "Error: Failed to archive repository $Owner/$RepoName. HTTP Status: $($response.StatusCode). Archived Status: $isArchived."
			Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"			
			Write-Host $errorMsg
			return
		}

		Write-Host "Repository $Owner/$RepoName successfully ${action}d"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
	}
	catch {
		$errorMsg = "Error: Failed to archive repository $Owner/$RepoName. Exception: $($_.Exception.Message)"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"		
		Write-Host $errorMsg
	}
}