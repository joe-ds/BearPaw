$full_file = "$HOME\BigBear\full.txt"
$den = "$HOME\BigBear\den\"
$repo = "USERNAME/den"

function Initialize-Backup {
    <#
    .SYNOPSIS
    Creates the necessary files and folders.
    .DESCRIPTION
    Creates the full.txt file and den to store files. The default location is $HOME\BigBear.
    .EXAMPLE
    Initialize-Backup
    #>
    if (-not (Test-Path $den)) {
        $current_dir = Get-Location
        if (-not (Test-Path (Split-Path $full_file))) {
            New-Item -Type Directory (Split-Path $full_file)
        }
        Set-Location (Split-Path $full_file)
        git clone "git@github.com:$repo.git"
    }

    if (-not (Test-Path $full_file)) {
        New-Item -Type File $full_file
    }
    Set-Location $current_dir
}

function Get-Hash {
    <#
    .SYNOPSIS
    Hash a string.
    .DESCRIPTION
    Hashes the given string using the SHA256 algorithm.
    .EXAMPLE
    Get-Hash "spam and eggs"
    #>
    param (
        [Parameter(Position=0)]
        [string] $s
    )

    $stringAsStream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.StreamWriter]::new($stringAsStream)
    $writer.write($s)
    $writer.Flush()
    $stringAsStream.Position = 0
    Return (Get-FileHash -InputStream $stringAsStream).Hash
}

function Deploy-Backup {
    <#
    .SYNOPSIS
    Copies all backed up files to their original locations.
    .DESCRIPTION
    This will restore the backup. It will also create any required folders for
    the files to be deployed to.
    .EXAMPLE
    Deploy-Backup
    #>
    Get-Content $full_file | ForEach-Object {
        if (($_.Length) -gt 0) {
            [String]$path_hash = Get-Hash $_
            if (Test-Path "$den\$path_hash\") {
                $roots = Split-Path $_
                if (Test-Path $roots) {
                    Copy-Item -Recurse "$den\$path_hash\*" -Destination $roots
                } else {
                    New-Item -Type Directory -Force $roots
                    Copy-Item -Recurse "$den\$path_hash\*" -Destination $roots
                }
            }
        }
    }
}

function Update-Backup {
    <#
    .SYNOPSIS
    Copies the latest versions of all marked files to the den.
    .DESCRIPTION
    The command will copy all marked files to the den. This command will also
    create a new folder in the den if for some reason the files have never
    been copied, so it will work well if you use a foreign file list that
    you've copied. This command will also back up all files to GitHub.
    .EXAMPLE
    Update-Backup
    #>
    Get-Content $full_file | ForEach-Object {
        if (($_.Length) -gt 0) {
            if (Test-Path $_) {
                [String]$path_hash = Get-Hash $_
                if (Test-Path "$den\$path_hash\") {
                    Copy-Item -Force -Recurse $_ "$den\$path_hash\"
                } else {
                    New-Item -Type Directory -Path "$den\$path_hash"
                    Copy-Item -Force -Recurse $_ "$den\$path_hash\"
                }
            } else {
                Write-Error "Cannot find $_."
            }
        }
    }
    $current_dir = Get-Location
    Set-Location $den
    git add ./*
    git commit -m "$(Get-Date)"
    git push
    Set-Location $current_dir
}

function Test-File {
    <#
    .SYNOPSIS
    Checks if a file's already marked for backup.
    .DESCRIPTION
    This is a little sub-function that checks a path against the existing list
    and returns if the path is already marked for backups.
    .EXAMPLE
    Test-File
    #>
    param (
        [Parameter(Position=0)]
        [string] $file
    )
    $matches = Select-String -Path $full_file -Pattern (Resolve-Path $file).Path -CaseSensitive -SimpleMatch
    return ($null -eq $matches)
}

function Add-Backup {
    <#
    .SYNOPSIS
    Marks a file for backup.
    .DESCRIPTION
    Marks a file or folder for backup, and includes all subfolders and files.
    .EXAMPLE
    Add-Backup README.txt
    #>
    param (
        [Parameter(Position=0)]
        [string] $file
    )
    
    $full_path = (Resolve-Path $file).Path

    if ((Test-Path -Path $file) -and (Test-File $file)) {
        echo "Adding!"
        Add-Content -Path $full_file -Value $full_path

        [String]$path_hash = Get-Hash $full_path
        if (Test-Path "$den\$path_hash\") {
            Copy-Item -Recurse $full_path "$den\$path_hash\"
        } else {
            New-Item -Type Directory -Path "$den\$path_hash"
            Copy-Item -Recurse $full_path "$den\$path_hash\"
        }
    }
}

function Remove-Backup {
    <#
    .SYNOPSIS
    Removes a file or folder marked for backup.
    .DESCRIPTION
    Removes a file or folder from the backup list. This command will also
    delete any existing backups.
    .EXAMPLE
    Remove-Backup README.txt
    #>
    param (
        [Parameter(Position=0)]
        [string] $file
    )
    
    if (Test-Path -Path $file) {
        $f = (Resolve-Path $file).Path

        if ((Get-Content $full_file) | Select-String -Pattern $f -CaseSensitive -SimpleMatch) {
            $hash_path = "$den\$(Get-Hash $f)"
            if (Test-Path $hash_path) {
                Remove-Item -Recurse -Force $hash_path
            }
        }

        $the_rest = (Get-Content $full_file) | Select-String -Pattern $f -NotMatch -CaseSensitive -SimpleMatch 
        if ($null -eq $the_rest) {
            Clear-Content $full_file
        } else {
            Set-Content $full_file $the_rest
        }
    }
}

function Show-Backup {
    <#
    .SYNOPSIS
    List all paths marked for backup.
    .DESCRIPTION
    Lists all files and folders marked for backup.
    .EXAMPLE
    Show-Backup
    #>
    Get-Content $full_file
}

Export-ModuleMember -Function Add-Backup
Export-ModuleMember -Function Show-Backup
Export-ModuleMember -Function Remove-Backup
Export-ModuleMember -Function Update-Backup
Export-ModuleMember -Function Initialize-Backup
Export-ModuleMember -Function Deploy-Backup
