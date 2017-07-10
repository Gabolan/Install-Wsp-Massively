function WaitForJobToFinish([string]$Identity)
{   
    $job = Get-SPTimerJob | ?{ $_.Name -like "*solution-deployment*$Identity*" }
    $maxwait = 30
    $currentwait = 0

    if (!$job)
    {
        Write-Host -f Red '[ERROR] Timer job not found'
    }
    else
    {
        $jobName = $job.Name
        Write-Host -NoNewLine "[WAIT] Esperando que finalice $jobName"        
        while (($currentwait -lt $maxwait))
        {
            Write-Host -f Green -NoNewLine .
            $currentwait = $currentwait + 1
            Start-Sleep -Seconds 2
            if (!(Get-SPTimerJob $jobName)){
                break;
            }
        }
        Write-Host  -f Green "...Done!"
    }
}
function RetractSolution([string]$Identity)
{
    Write-Host -ForegroundColor Yellow "[RETRACT] Retirando $file.Name"	
    $solution = Get-SPSolution | where { $_.Name -match $Identity }
    if($solution.ContainsWebApplicationResource)
    {             
        Write-Host -NoNewLine "[RETRACT] Desistalando $Identity"            
        Uninstall-SPSolution -identity $Identity  -allwebapplications -Confirm:$false
        Write-Host -f Green "...Done!"
    }
    else
    {
        Write-Host -NoNewLine "[RETRACT] Desistalando $Identity"      
        Uninstall-SPSolution -identity $Identity -Confirm:$false    
        Write-Host -f Green "...Done!"
    }

    (WaitForJobToFinish $Identity)

    Write-Host -NoNewLine  '[UNINSTALL] Removing solution:' $SolutionName
    Remove-SPSolution -Identity $Identity -Confirm:$false
    Write-Host -f Green "...Done!"
}
function ActivarCaracteristica([string]$NombreCaracteristica)
{
	$Feature = Get-SPFeature | where { $_.DisplayName -like "*"+$NombreCaracteristica+"*" }
	If ($Feature.Scope -eq [Microsoft.SharePoint.SPFeatureScope]::WebApplication)
	{
		$Feature = Get-SPFeature -Identity $FeatureID -WebApplication $SiteUrl -ErrorAction SilentlyContinue
		Enable-SPFeature -Identity $FeatureID -Url $SiteUrl  -Confirm:$false 
	}
	ElseIf ($Feature.Scope -eq [Microsoft.SharePoint.SPFeatureScope]::Site)
	{
		$Feature = Get-SPFeature -Identity $FeatureID -Site $SiteUrl -ErrorAction SilentlyContinue
		Enable-SPFeature -Identity $FeatureID -Url $SiteUrl  -Confirm:$false 
	}
}

$WspFolderPath = "D:\InstallWSP\wsp"
$url = "http://bncpba" 
$wspFiles = get-childitem $WspFolderPath | where {$_.Name -like "*.wsp"}
$date = Get-Date
Write-host 'Inicio despliegue ' $date
ForEach($file in $wspFiles)
{
    $isInstalled = Get-SPSolution | where { $_.Name -eq $file.Name }
	if($isInstalled)
	{	     
        (RetractSolution $file.Name)
	}
	
	$solution = Add-SPSolution -LiteralPath ($WspFolderPath + "\" + $file.Name)
	if ( $solution.ContainsWebApplicationResource ) {
    	   Write-Host -ForegroundColor Green "Desplegando $file.Name en $url"
    	   Install-SPSolution -Identity $file.Name -GacDeployment  -Force -Webapplication $url
	}
	else {
    	   Write-Host -ForegroundColor Green "Desplegando $file.Name"
           Install-SPSolution -Identity $file.Name -GacDeployment -Force
	}
	
	$wsp = Get-SPSolution | Where{$_.Name -eq $file.Name}

	if ($solution.Deployed -eq $false ) {
    	   $counter = 1
    	   $maximum = 50
    	   $sleeptime = 5
    	   while( ($solution.JobExists -eq $true ) -and ( $counter -lt $maximum  ) ) {
        	write-host -ForegroundColor yellow "Desplegando..."
        	sleep $sleeptime
        	$counter++
    	    }
	}
	Write-Host ""
	Write-Host -ForegroundColor Green "$file.Name Desplegada"
}
$date = Get-Date
Write-host 'Fin despliegue ' $date
