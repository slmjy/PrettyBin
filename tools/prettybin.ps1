function Add-ProbingToAppConfig(
    [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$appConfigContent, 
    [ValidateNotNullOrEmpty()]$probingSubdirectories = @("lib")) 
{
    <#
    .SYNOPSIS
    Adds probing tag to App.config to search for dependencies in additional folders
    .DESCRIPTION
        Adds-
        <configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
            <runtime>	
                <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
                    <probing privatePath="lib;libs" />		
                </assemblyBinding>		
            </runtime>
        </configuration>
    .EXAMPLE
    Add-ProbingToAppConfig (get-content 'path to app.config') "lib"
    .EXAMPLE
    Add-ProbingToAppConfig (get-content 'path to app.config') "lib","libs"
    .PARAMETER appConfigContent
    Content of App.config, not location. Can be either xml object or convertible to xml
    .PARAMETER probingSubdirectories
    Sub-directories to search for dependencies. Are relative to App.Config location and cannot be absolute
    #>

    $app = [xml]$appConfigContent

    # If a Namespace URI was not given, use the Xml document's default namespace.
    $NamespaceAppURI = $app.DocumentElement.NamespaceURI 
    # In order for SelectSingleNode() to actually work, we need to use the fully qualified node path along with an Xml Namespace Manager, so set them up.
    $xmlNsManager.AddNamespace("appns", $NamespaceAppURI)	

    # Adding of configuration section
    $configurationNode =  $app.SelectSingleNode("//appns:configuration", $xmlNsManager)

    if ($configurationNode   -eq $null)
    {
        Write-Host '[PRETTYBIN] No Configuration Node. Creating'
        $configurationNode = $app.CreateElement('Configuration', $NamespaceAppURI )
        $configurationNode.SetAttribute("xmlns:xdt" ,"http://schemas.microsoft.com/XML-Document-Transform")
        $app.AppendChild($configurationNode) 
    }

    # Adding of runtime section
    $runtimeNode =  $configurationNode.SelectSingleNode("//appns:runtime", $xmlNsManager)
    
    if ($runtimeNode   -eq $null)
    {
        Write-Host '[PRETTYBIN] No runtime Node. Creating'
        $runtimeNode = $app.CreateElement('runtime', $NamespaceAppURI )
        $configurationNode.AppendChild($runtimeNode) 
    }

    # Adding of assemblyBinding section
    Write-Host '[PRETTYBIN] runtimeNode items'
    $assemblyBindingNode = $null
    foreach ($item in $runtimeNode.ChildNodes)
    {
        if ($item.Name -eq 'assemblyBinding')
        {
            $assemblyBindingNode = $item
            break
        }
    }

    #$assemblyBindingNode =  $runtimeNode.SelectSingleNode("//appns:assemblyBinding", $xmlNsManager)
    
    if ($assemblyBindingNode -eq $null)
    {
        Write-Host '[PRETTYBIN] No assemblyBinding Node. Creating'
        $assemblyBindingNode = $app.CreateElement('assemblyBinding', $NamespaceAppURI )
        $runtimeNode.AppendChild($assemblyBindingNode) 
    }
    $assemblyBindingNode.SetAttribute("xmlns" ,"urn:schemas-microsoft-com:asm.v1")

    # Adding of probing section
    $probingNode =  $assemblyBindingNode.SelectSingleNode("//appns:probing", $xmlNsManager)
    
    if ($probingNode -eq $null)
    {
        Write-Host '[PRETTYBIN] No probing Node. Creating'
        $probingNode = $app.CreateElement('probing', $NamespaceAppURI )
        $assemblyBindingNode.AppendChild($probingNode) 
    }

    $probingNode.SetAttribute("privatePath", ($probingSubdirectories -join ";"))

    return $app
}


function Add-MSBuildTaskToMoveDependencies(
    [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$projectxml, 
    [ValidateNotNullOrEmpty()]$subfolder = "lib") 
{
    <#
    .SYNOPSIS
    Adds MsBuild task to move all dlls, xmls and so on to lib subfolder
    .DESCRIPTION
        <Target Name="AfterBuild">
            <ItemGroup>
                <MoveToLibFolder Include="$(OutputPath)*.dll ; $(OutputPath)*.pdb ; $(OutputPath)*.xml" /> 
            </ItemGroup>
            <Move SourceFiles="@(MoveToLibFolder)" DestinationFolder="$(OutputPath)lib" OverwriteReadOnlyFiles="true" />
        </Target>
    .EXAMPLE
    .EXAMPLE
    .PARAMETER projectxml
    Content of App.config, not location. Can be either xml object or convertible to xml
    .PARAMETER subfolder
    Specifies subfolder where to move libraries and other embedded runtime dependencies
    #>

    # If a Namespace URI was not given, use the Xml document's default namespace.
    $NamespaceURI = $doc.DocumentElement.NamespaceURI 
    Write-Host $NamespaceURI
    # In order for SelectSingleNode() to actually work, we need to use the fully qualified node path along with an Xml Namespace Manager, so set them up.
    $xmlNsManager = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
    $xmlNsManager.AddNamespace("ns", $NamespaceURI)


    #  ============        This script attemps to Create this tags in csproj: ========
    #
    # <Target Name="AfterBuild">
    #      <ItemGroup>
    #           <MoveToLibFolder Include="$(OutputPath)*.dll ; $(OutputPath)*.pdb ; $(OutputPath)*.xml" /> 
    #      </ItemGroup>
    #      <Move SourceFiles="@(MoveToLibFolder)" DestinationFolder="$(OutputPath)lib" OverwriteReadOnlyFiles="true" />
    # </Target>




    $targetNode =  $doc.SelectSingleNode("//ns:Project/ns:Target[@Name='AfterBuild']", $xmlNsManager)

    if ($targetNode   -eq $null)
    {
    Write-Host '[PRETTYBIN] No Target AfterBuild Node. Creating'
    $targetNode = $doc.CreateElement('Target', $NamespaceURI )
    $targetNode.SetAttribute("Name" ,"AfterBuild")
    $doc.Project.AppendChild($targetNode) 
    }


    $filesToMoveNode = $targetNode.SelectSingleNode("//ns:ItemGroup/ns:MoveToLibFolder", $xmlNsManager)

    if ($filesToMoveNode -eq $null)
    {
    Write-Host '[PRETTYBIN] No ItemGroup whith MoveToLibFolder tag. Creating'
    $itemGroup =  $doc.CreateElement('ItemGroup', $NamespaceURI)        
    $filesToMoveNode = $doc.CreateElement('MoveToLibFolder', $NamespaceURI)

    $itemGroup.AppendChild($filesToMoveNode)
    $targetNode.AppendChild($itemGroup)
    }

    $filesToMoveNode.SetAttribute("Include" ,'$(OutputPath)*.dll ; $(OutputPath)*.pdb ; $(OutputPath)*.xml')


    $MoveNode = $targetNode.SelectSingleNode('//ns:Move[contains(@SourceFiles,"@(MoveToLibFolder)")]', $xmlNsManager)
    if ($MoveNode -eq $null)
    {
        Write-Host '[PRETTYBIN] No Move tag in AfterBuild Target. Creating'
        $MoveNode = $doc.CreateElement('Move', $NamespaceURI)
        $MoveNode.SetAttribute("SourceFiles" ,'@(MoveToLibFolder)')
        $targetNode.AppendChild($MoveNode)
    }
    $MoveNode.SetAttribute("DestinationFolder",'$(OutputPath)lib')
    $MoveNode.SetAttribute("OverwriteReadOnlyFiles","true")

    $doc
}