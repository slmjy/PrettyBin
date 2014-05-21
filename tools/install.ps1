param($installPath, $toolsPath, $package, $project)


Try
{
	 $path = $project.FullName
     Write-Host 'Install PrettifyBin; '
     [xml]$doc =  [xml](Get-Content $path)


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
        Write-Host 'No Target AfterBuild Node. Creating'
		$targetNode = $doc.CreateElement('Target', $NamespaceURI )
        $targetNode.SetAttribute("Name" ,"AfterBuild")
		$doc.Project.AppendChild($targetNode) 
	}

    
    $filesToMoveNode = $targetNode.SelectSingleNode("//ns:ItemGroup/ns:MoveToLibFolder", $xmlNsManager)

	if ($filesToMoveNode -eq $null)
    {
        Write-Host 'No ItemGroup whith MoveToLibFolder tag. Creating'
        $itemGroup =  $doc.CreateElement('ItemGroup', $NamespaceURI)        
        $filesToMoveNode = $doc.CreateElement('MoveToLibFolder', $NamespaceURI)

        $itemGroup.AppendChild($filesToMoveNode)
        $targetNode.AppendChild($itemGroup)
    }
   
    $filesToMoveNode.SetAttribute("Include" ,'$(OutputPath)*.dll ; $(OutputPath)*.pdb ; $(OutputPath)*.xml')
   

    $MoveNode = $targetNode.SelectSingleNode('//ns:Move[contains(@SourceFiles,"@(MoveToLibFolder)")]', $xmlNsManager)
    if ($MoveNode -eq $null)
    {
         Write-Host 'No Move tag in AfterBuild Target. Creating'
         $MoveNode = $doc.CreateElement('Move', $NamespaceURI)
         $MoveNode.SetAttribute("SourceFiles" ,'@(MoveToLibFolder)')
         $targetNode.AppendChild($MoveNode)
    }
    $MoveNode.SetAttribute("DestinationFolder",'$(OutputPath)lib')
    $MoveNode.SetAttribute("OverwriteReadOnlyFiles","true")

    $doc.Save($path)
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Host  $ErrorMessage
	 Write-Host   $FailedItem
    Break
}

