function Get-FLTorrent {
    [OutputType('Filelist.Torrent')]
    [CmdletBinding()]
    Param (
        #TODO 'Clean out Parameters'
        [Parameter()]
        [string]
        $Name,
        [Parameter()]
        [ValidateSet('Hibrid','Relevanta','Data','Marime','Downloads','Peers')]
        [string]
        $Sort='Hibrid',
        [Parameter()]
        [int]
        $Pages
    )
    DynamicParam {
        $ParameterName = 'Category'
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $AttributeCollection.Add($ParameterAttribute)
        try {
            $HTML = Invoke-WebRequest -Uri ('{0}/browse.php' -f $Script:BaseUri) -WebSession $Script:session
        } catch {
            break
        }
        
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

    BEGIN {
        $Category = $PsBoundParameters[$ParameterName]
        if ($Category) {
            foreach ($Item in $CategoriesArray) {
                if ($Item.Category -eq $Category) {
                    $CategoryId = ('cat={0}' -f $Item.CategoryID)
                }
            }
        }
        if ( -Not ($Script:session) ) {
            Write-Output 'You must first login to Filelist using the cmdlet Invoke-FLLogin'
            Break
        }
        switch ($Sort) {
            'Hibrid' {$SortID = '0'}
            'Relevanta' {$SortID = '1'}
            'Data' {$SortID = '2'}
            'Marime' {$SortID = '3'}
            'Downloads' {$SortID = '4'}
            'Peers' {$SortID = '5'}
        }
        if ($Name -or $Category) {
            $Name = $Name -replace ' ', '+'
            $Query = ('{0}/browse.php?search={1}&{2}&searchin=0&sort={3}' -f $Script:BaseUri, $Name, $CategoryId, $SortID)
        } else {
            $Query = ('{0}/browse.php' -f $Script:BaseUri)
        }
        
        #Building the HTML Variable
        try {
            $HTML = (Invoke-WebRequest -Uri $Query -WebSession $Script:session -UseBasicParsing -ErrorAction Stop).RawContent
            if ($Pages) {
                for ($i = 1 ; $i -lt $Pages; $i++) {
                    $HTML += (Invoke-WebRequest -Uri ('{0}?page={1}' -f $Query, [string]$i) -WebSession $Script:session -UseBasicParsing -ErrorAction Stop).RawContent#
                }
            }
        } catch {
            Write-Error $Error[0]
            break
        }
            
        $Document = New-Object -TypeName HtmlAgilityPack.HtmlDocument
        $Document.LoadHtml($HTML)
        $TorrentRows = $Document.DocumentNode.SelectNodes('//div[@class="torrentrow"]')
        
        
    }

    PROCESS {
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
                Length = [long]$Size
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