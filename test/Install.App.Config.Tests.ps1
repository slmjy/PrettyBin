. $PSScriptRoot/../tools/prettybin.ps1

$configs = "$PSScriptRoot/configs"

Describe 'Add-PrettyProbingToAppConfig' {

    $ErrorActionPreference = "Stop"

    function GetProbingTag {
        
    }

    $modifiedAppConfig = "TestDrive:\out.xml"
    set-content $modifiedAppConfig -value "-"
    $modifiedAppConfig = (get-item $modifiedAppConfig ).FullName

    $tests = {
        It 'Adds probing Tag to a simple app.config' {         
            @(gc $modifiedAppConfig | where { $_ -like "*<probing*" } ).Count | Should -Be 1 -Because "probing tag should be only once: `n$(gc $modifiedAppConfig)`n"
        }

        It 'Does not live empty xmlns="" attribute' {
            $modifiedAppConfig | Should -Not -FileContentMatch "xmlns=`"`"" -Because "empty xmlns should not be in: `n$(gc $modifiedAppConfig)`n"
        }
    }

    get-childitem $configs -Recurse -File | ForEach-Object {
        $folderName = split-path ( split-path $_.FullName -Parent) -Leaf

        Context "$folderName $($_.BaseName) app.config" {
            Context "With namespaces" {
                <# 
                $xmlWithNamespace = (Get-content $_.FullName -Raw).Replace("configuration", 'configuration xmlns="http://schemas.microsoft.com/')

                $xml = Add-PrettyProbingToAppConfig($xmlWithNamespace ) "lib", "libs" 
                $xml.Save($modifiedAppConfig)

                . $tests 
                #>
            }

            Context "Without namespaces" {
        
                $xml = Add-PrettyProbingToAppConfig (Get-content $_.FullName) "lib", "libs" 
                $xml.Save($modifiedAppConfig)

                . $tests
            }
           
           
        } 
    }
   
}