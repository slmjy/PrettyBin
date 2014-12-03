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
	
	#  ============        This script attemps to Edit this tags in App.config: ========
    #
	# <configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
	#		<runtime>	
	#			<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
	#				<probing privatePath="lib;libs" />		
	#			</assemblyBinding>		
	#		</runtime>
	# </configuration>
	
	# TODO: Получение $app = App.config. 
	
	# Добавление секции configuration
	# Какое мне нужно неймспейс, ns? Что делает xmlNsManager?
	$configurationNode =  $app.SelectSingleNode("//ns:configuration", $xmlNsManager)
	 
    if ($configurationNode   -eq $null)
	{
        Write-Host 'No Configuration Node. Creating'
		# Для чего тут нужен NamespaceURI
		$configurationNode = $doc.CreateElement('Configuration', $NamespaceURI )
        $configurationNode.SetAttribute("xmlns:xdt" ,"http://schemas.microsoft.com/XML-Document-Transform")
		$app.AppendChild($configurationNode) 
	}
	
	# Добавление runtime
	$runtimeNode =  $configurationNode.SelectSingleNode("//ns:runtime", $xmlNsManager)
	 
    if ($runtimeNode   -eq $null)
	{
        Write-Host 'No runtime Node. Creating'
		$runtimeNode = $doc.CreateElement('runtime', $NamespaceURI )
		$configurationNode.AppendChild($runtimeNode) 
	}
	
	# Добавление assemblyBinding
	$assemblyBindingNode =  $runtimeNode.SelectSingleNode("//ns:assemblyBinding", $xmlNsManager)
	 
    if ($assemblyBindingNode   -eq $null)
	{
        Write-Host 'No assemblyBinding Node. Creating'
		$assemblyBindingNode = $doc.CreateElement('assemblyBinding', $NamespaceURI )
		$runtimeNode.AppendChild($assemblyBindingNode) 
	}
	$assemblyBindingNode.SetAttribute("xmlns" ,"urn:schemas-microsoft-com:asm.v1")
	
	# Добавление probing
	$probingNode =  $assemblyBindingNode.SelectSingleNode("//ns:probing", $xmlNsManager)
	 
    if ($probingNode   -eq $null)
	{
        Write-Host 'No probing Node. Creating'
		$probingNode = $doc.CreateElement('probing', $NamespaceURI )
		$assemblyBindingNode.AppendChild($probingNode) 
	}
	$probingNode.SetAttribute("privatePath" ,"lib;libs")
	
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Host  $ErrorMessage
	 Write-Host   $FailedItem
    Break
}

