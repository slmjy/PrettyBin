param($installPath, $toolsPath, $package, $project)


. ./prettybin.ps1

$csprojLocation = $project.FullName

Write-Host '[PRETTYBIN] Searching for App.config'
$appConfigItem = $project.ProjectItems | Where-Object { $_.Name -eq "App.config" }	
if ($null -eq $appConfigItem) {
    throw [System.IO.FileNotFoundException] "Project '$csprojLocation' does not have App.config. PrettyBin is for exetutable projects only."
}
$configPath = $appConfigItem | ForEach-Object { $_.Properties } | Where-Object { $_.Name -eq "LocalPath" } | ForEach-Object { $_.Value }	
if (!(Test-Path $configPath -PathType Leaf)) {
    throw [System.IO.FileNotFoundException] "Cannot find app.config file at '$configPath'"
}
else {
    Write-Host "[PRETTYBIN] App.config found in '$configPath'"
}

 
Write-Host '[PrettyBin] Adding AfterBuild MSBUILD task to project file'
# <Target Name="AfterBuild">
# 	<ItemGroup>
# 		<MoveToLibFolder Include="$(OutputPath)*.dll ; $(OutputPath)*.pdb ; $(OutputPath)*.xml" /> 
# 	</ItemGroup>
# 	<Move SourceFiles="@(MoveToLibFolder)" DestinationFolder="$(OutputPath)lib" OverwriteReadOnlyFiles="true" />
# </Target>

$modifiedCsProj = Add-PrettyMSBuildTaskToMoveDependencies (Get-Content $csprojLocation) "lib"
$modifiedCsProj.Save($csprojLocation)

Write-Host '[PrettyBin] Adding Probing tak to App.config'
# <configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
#		<runtime>	
#			<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
#				<probing privatePath="lib;libs" />		
#			</assemblyBinding>		
#		</runtime>
# </configuration>

$modifiedAppConig = Add-PrettyProbingToAppConfig (Get-Content $configPath) "lib", "libs"
$modifiedAppConig.save($configPath)


