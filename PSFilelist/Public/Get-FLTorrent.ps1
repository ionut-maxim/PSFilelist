function Get-FLTorrent {
    [OutputType('Filelist.Torrent')]
    [CmdletBinding()]
    Param (
        #TODO 'Clean out Parameters'
        [Parameter()]
        [string]
        $Name,
        # [Parameter()]
        # [string]
        # $Category='cat=0',
        [Parameter()]
        [string]
        $Search='searchin=0',
        [Parameter()]
        [string]
        $Sort='sort=0',
        [Parameter()]
        [int]
        $Pages
    )
    DynamicParam {
        $ParameterName = 'Category'
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        #$ParameterAttribute.Mandatory = $true
        #$ParameterAttribute.Position = 1
        $AttributeCollection.Add($ParameterAttribute)
        $HTML = Invoke-WebRequest -Uri ('{0}/browse.php' -f $Script:BaseUri) -WebSession $Script:session
        $Document = New-Object -TypeName HtmlAgilityPack.HtmlDocument
        $Document.LoadHtml($HTML)
        $Links = $Document.DocumentNode.SelectNodes('//td[@class="noborder"]//a')
        foreach ($Link in $Links) {
            if ($Link.Attributes.Value -match 'cat') {
                $CategoryId = [int]($Link.Attributes.Value).Replace('browse.php?cat=','')
                $Category = [string]($Link.InnerText).Trim()
            }
            [array]$CategoriesArray += New-Object -TypeName PSCustomObject @{
                Category = $Category
                CategoryID = $CategoryId
            }
        }
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($CategoriesArray.Category)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        $Category = $PsBoundParameters[$ParameterName]
    }

    process {
        if ($Category) {
            foreach ($Item in $CategoriesArray) {
                if ($Item.Category -eq $Category) {
                    $CategoryId = ('cat={0}' -f $Item.CategoryID)
                }
            }
        }
        if ($Name -or $Category) {
            $Name = $Name -replace ' ', '+'
            $Query = ('{0}/browse.php?search={1}&{2}&{3}&{4}' -f $Script:BaseUri, $Name, $CategoryId, $Search, $Sort)
        } else {
            $Query = ('{0}/browse.php' -f $Script:BaseUri)
        }
        
        #Building the HTML Variable
        $HTML = (Invoke-WebRequest -Uri $Query -WebSession $Script:session -UseBasicParsing).RawContent
        if ($Pages) {
            for ($i = 1 ; $i -le $Pages; $i++) {
                $HTML += (Invoke-WebRequest -Uri ('{0}?page={1}' -f $Query, [string]$i) -WebSession $Script:session -UseBasicParsing).RawContent
            }
        }

        $Document = New-Object -TypeName HtmlAgilityPack.HtmlDocument
        $Document.LoadHtml($HTML)
        $TorrentRows = $Document.DocumentNode.SelectNodes('//div[@class="torrentrow"]')
        foreach ($TorrentRow in $TorrentRows) {
            #Parse Genres
            $Nodes = $TorrentRow.ChildNodes[1].ChildNodes[0].ChildNodes 
            foreach ($Node in $Nodes) {
                If ($Node.Name -eq 'font') {
                    $Genres = ((($Node.InnerText).Trim('[]')).Split(',|')).Trim()
                }
            }
            #Parse Date
            $DateTime = $TorrentRow.ChildNodes[5].ChildNodes.ChildNodes.ChildNodes.InnerHtml
            $DateTime = $DateTime -split '<br>'
            $DateAdded = [datetime]::ParseExact(('{0} {1}' -f $DateTime[1], $DateTime[0]), 'dd/MM/yyyy HH:mm:ss', $null)

            #Tags
            $Tags = $null
            $Nodes = $TorrentRow.ChildNodes[1].ChildNodes.ChildNodes
            foreach ($Node in $Nodes) {
                If ($Node.Name -eq 'img') {
                    foreach ($Attribute in $Node.Attributes) {
                        If ($Attribute.Name -eq 'alt') {
                            [array]$Tags += $Attribute.Value
                        }
                    }
                }
            }

            #File Size
            $Size = $null
            [array]$SizeArray = $TorrentRow.ChildNodes[6].ChildNodes.ChildNodes.InnerHtml -split '<br>'
            Switch ($SizeArray[1]) {
                'kB' { $Size = [int]$SizeArray[0] * 1024 }
                'MB' { $Size = [int]$SizeArray[0] * 1024 * 1024 }
                'GB' { $Size = [int]$SizeArray[0] * 1024 * 1024 * 1024 }
            }

            #Building Object
            $Object = New-Object -TypeName PSCustomObject -Property @{
                Name = [string]$TorrentRow.ChildNodes[1].ChildNodes[0].ChildNodes[0].InnerText
                Id = [int]($TorrentRow.ChildNodes[1].ChildNodes[0].ChildNodes[0].Attributes[0].Value).Replace('details.php?id=','')
                Genre = [string[]]$Genres
                Snatched = [int]($TorrentRow.ChildNodes[7].ChildNodes.InnerText).Replace('times','')
                Category = [string]$TorrentRow.ChildNodes[0].ChildNodes.ChildNodes.ChildNodes.Attributes[2].Value
                CategoryID = [int]($TorrentRow.ChildNodes[0].ChildNodes.ChildNodes.Attributes.Value).Replace('browse.php?cat=','')
                DateAdded = $DateAdded
                Size = [long]$Size
                Seeders = [int]$TorrentRow.ChildNodes[8].InnerText
                Leechers = [int]$TorrentRow.ChildNodes[9].InnerText
                Uploader = [string]$TorrentRow.ChildNodes[10].InnerText
                Tag = $Tags
            }
            $Object.pstypenames.insert(0,'Filelist.Torrent')
            Write-Output -InputObject $Object
            # Write-Output $TorrentRow
        }
    }
}