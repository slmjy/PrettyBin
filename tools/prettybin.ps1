
#requires -version 2

function GetXmlNodeChild([parameter(ValueFromPipeline=$true)]$node, $name) {
    if ($node) {
        
    }    
}
function Add-PrettyProbingToAppConfig(
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
    Add-PrettyProbingToAppConfig (get-content 'path to app.config') "lib"
    .EXAMPLE
    Add-PrettyProbingToAppConfig (get-content 'path to app.config') "lib","libs"
    .PARAMETER appConfigContent
    Content of App.config, not location. Can be either xml object or convertible to xml
    .PARAMETER probingSubdirectories
    Sub-directories to search for dependencies. Are relative to App.Config location and cannot be absolute
    #>

    $app = [xml]$appConfigContent

    $namespace = "appns:"

    # If a Namespace URI was not given, use the Xml document's default namespace.
    if (!$NamespaceAppURI) {
        $NamespaceAppURI = $app.DocumentElement.NamespaceURI 
    }

    # In order for SelectSingleNode() to actually work, we need to use the fully qualified node path along with an Xml Namespace Manager, so set them up.
    $xmlNsManager = New-Object System.Xml.XmlNamespaceManager($app.NameTable)
    $xmlNsManager.AddNamespace("ns2", "urn:schemas-microsoft-com:asm.v1")

    if ($NamespaceAppURI) {
        $xmlNsManager.AddNamespace("appns", $NamespaceAppURI)
    } else {
        $namespace = ""
        $NamespaceAppURI = $null
    }    	

    function NewEl($parent, $name) {
        Write-Host "[PRETTYBIN] New '$name' node under '$($parent.Name)'"
        $el = if ($NamespaceAppURI) {
            $app.CreateElement($name, $parent.NamespaceURI )
        } else {
            $app.CreateElement($name, $parent.NamespaceURI)
        }

        $parent.AppendChild($el) | Out-Null
        return $el
    }

    function GetOrNewEl($parent, $name) {
        $el = if ($parent.HasChildNodes) { $parent.ChildNodes | Where-Object { $_.Name -eq $name } | select -first 1 } 
        if (!$el) { $el = NewEl $parent $name}
        return $el
    }

    # Adding of configuration section
    $configurationNode =  GetOrNewEl  $app 'configuration'
    $configurationNode.SetAttribute("xmlns:xdt" ,"http://schemas.microsoft.com/XML-Document-Transform")

    # Adding of runtime section
    $runtimeNode =  GetOrNewEl $configurationNode 'runtime'
    $assemblyBindingNode = GetOrNewEl $runtimeNode 'assemblyBinding'
    $assemblyBindingNode.SetAttribute("xmlns" ,"urn:schemas-microsoft-com:asm.v1")

    # Adding of probing section
    $probingNode = GetOrNewEl $assemblyBindingNode 'probing'
    $probingNode.SetAttribute("privatePath", ($probingSubdirectories -join ";"))

    return $app
}


function Add-PrettyMSBuildTaskToMoveDependencies(
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

    if ($null -eq $targetNode)
    {
    Write-Host '[PRETTYBIN] No Target AfterBuild Node. Creating'
        $targetNode = $doc.CreateElement('Target', $NamespaceURI )
        $targetNode.SetAttribute("Name" ,"AfterBuild")
        $doc.Project.AppendChild($targetNode) 
    }


    $filesToMoveNode = $targetNode.SelectSingleNode("//ns:ItemGroup/ns:MoveToLibFolder", $xmlNsManager)

    if ($null -eq $filesToMoveNode)
    {
    Write-Host '[PRETTYBIN] No ItemGroup whith MoveToLibFolder tag. Creating'
    $itemGroup =  $doc.CreateElement('ItemGroup', $NamespaceURI)        
    $filesToMoveNode = $doc.CreateElement('MoveToLibFolder', $NamespaceURI)

    $itemGroup.AppendChild($filesToMoveNode)
    $targetNode.AppendChild($itemGroup)
    }

    $filesToMoveNode.SetAttribute("Include" ,'$(OutputPath)*.dll ; $(OutputPath)*.pdb ; $(OutputPath)*.xml')


    $MoveNode = $targetNode.SelectSingleNode('//ns:Move[contains(@SourceFiles,"@(MoveToLibFolder)")]', $xmlNsManager)
    if ($null -eq $MoveNode)
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