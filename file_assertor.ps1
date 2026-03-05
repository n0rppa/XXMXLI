param(
    [string]$Source = ".",
    [string]$Mode = "extension",   # extension | date | type
    [switch]$Recurse = $true,
    [switch]$DryRun = $false,
    [switch]$HandleDuplicates = $true,
    [switch]$Interactive = $false
)

$LogFile = "organizer_log.txt"
$script:exitMenu = $false

function Write-Log {
    param([string]$msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time $msg" | Tee-Object -FilePath $LogFile -Append
}

function Clear-HostSafe {
    <#
    .SYNOPSIS
    Safely clears the host screen with error handling
    #>
    try {
        Clear-Host -ErrorAction SilentlyContinue
    } catch {
        # Fallback for environments where Clear-Host fails
        Write-Host "`n`n`n`n`n`n`n`n`n`n"
    }
}

# ============================================================================
# FILE & FOLDER ASSERTION FUNCTIONS
# ============================================================================

function Assert-PathExists {
    <#
    .SYNOPSIS
    Validates if a path exists and returns detailed results
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )
    
    $result = [PSCustomObject]@{
        Path = $Path
        Exists = (Test-Path -Path $Path)
        IsFile = $false
        IsDirectory = $false
        FullPath = ""
        ErrorMessage = ""
    }
    
    try {
        if (Test-Path -Path $Path) {
            $item = Get-Item -Path $Path -ErrorAction Stop
            $result.FullPath = $item.FullName
            $result.IsFile = $item -is [System.IO.FileInfo]
            $result.IsDirectory = $item -is [System.IO.DirectoryInfo]
        } else {
            $result.ErrorMessage = "Path does not exist"
        }
    } catch {
        $result.ErrorMessage = $_.Exception.Message
    }
    
    return $result
}

function Assert-FileProperties {
    <#
    .SYNOPSIS
    Validates file existence and returns comprehensive properties
    #>
    param(
        [Parameter(Mandatory=$true)][string]$FilePath
    )
    
    $result = @{
        Exists = $false
        Path = $FilePath
        Name = ""
        Size = 0
        CreatedTime = $null
        ModifiedTime = $null
        AccessTime = $null
        IsReadOnly = $false
        Attributes = ""
        Extension = ""
        ErrorMessage = ""
    }
    
    try {
        if (Test-Path -Path $FilePath -PathType Leaf) {
            $file = Get-Item -Path $FilePath -ErrorAction Stop
            $result.Exists = $true
            $result.Name = $file.Name
            $result.Size = $file.Length
            $result.CreatedTime = $file.CreationTime
            $result.ModifiedTime = $file.LastWriteTime
            $result.AccessTime = $file.LastAccessTime
            $result.IsReadOnly = $file.Attributes -match "ReadOnly"
            $result.Attributes = $file.Attributes.ToString()
            $result.Extension = $file.Extension
        } else {
            $result.ErrorMessage = "File not found or path is not a file"
        }
    } catch {
        $result.ErrorMessage = $_.Exception.Message
    }
    
    return $result
}

function Assert-FolderProperties {
    <#
    .SYNOPSIS
    Validates folder and returns folder-specific properties
    #>
    param(
        [Parameter(Mandatory=$true)][string]$FolderPath,
        [switch]$Recurse
    )
    
    $result = @{
        Exists = $false
        Path = $FolderPath
        Name = ""
        FileCount = 0
        SubFolderCount = 0
        TotalSize = 0
        CreatedTime = $null
        ModifiedTime = $null
        IsEmpty = $true
        FullPath = ""
        ErrorMessage = ""
    }
    
    try {
        if (Test-Path -Path $FolderPath -PathType Container) {
            $folder = Get-Item -Path $FolderPath -ErrorAction Stop
            $result.Exists = $true
            $result.Name = $folder.Name
            $result.CreatedTime = $folder.CreationTime
            $result.ModifiedTime = $folder.LastWriteTime
            $result.FullPath = $folder.FullName
            
            if ($Recurse) {
                $items = Get-ChildItem -Path $FolderPath -Recurse -ErrorAction SilentlyContinue
            } else {
                $items = Get-ChildItem -Path $FolderPath -ErrorAction SilentlyContinue
            }
            
            if ($items) {
                $result.IsEmpty = $false
                $result.FileCount = @($items | Where-Object { $_ -is [System.IO.FileInfo] }).Count
                $result.SubFolderCount = @($items | Where-Object { $_ -is [System.IO.DirectoryInfo] }).Count
                $result.TotalSize = ($items | Where-Object { $_ -is [System.IO.FileInfo] } | Measure-Object -Property Length -Sum).Sum
            }
        } else {
            $result.ErrorMessage = "Folder not found or path is not a directory"
        }
    } catch {
        $result.ErrorMessage = $_.Exception.Message
    }
    
    return $result
}

function Assert-FileReadable {
    <#
    .SYNOPSIS
    Checks if a file is readable by the current user
    #>
    param(
        [Parameter(Mandatory=$true)][string]$FilePath
    )
    
    $result = @{
        Path = $FilePath
        IsReadable = $false
        ErrorMessage = ""
    }
    
    try {
        if (Test-Path -Path $FilePath -PathType Leaf) {
            $fileStream = [System.IO.File]::OpenRead($FilePath)
            $fileStream.Close()
            $result.IsReadable = $true
        } else {
            $result.ErrorMessage = "File not found"
        }
    } catch {
        $result.ErrorMessage = $_.Exception.Message
    }
    
    return $result
}

function Assert-DriveSpace {
    <#
    .SYNOPSIS
    Checks available disk space for a given path
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )
    
    $result = @{
        Path = $Path
        Drive = ""
        TotalSize = 0
        UsedSpace = 0
        FreeSpace = 0
        PercentUsed = 0
        ErrorMessage = ""
    }
    
    try {
        if (Test-Path -Path $Path) {
            $pathInfo = Get-Item -Path $Path -ErrorAction Stop
            $fullPath = $pathInfo.FullName
            $driveLetter = [System.IO.Path]::GetPathRoot($fullPath)
            
            $drive = Get-PSDrive -Name $driveLetter.TrimEnd('\') -ErrorAction Stop
            $result.Drive = $driveLetter
            $result.TotalSize = $drive.Used + $drive.Free
            $result.UsedSpace = $drive.Used
            $result.FreeSpace = $drive.Free
            $result.PercentUsed = [math]::Round(($drive.Used / $result.TotalSize) * 100, 2)
        } else {
            $result.ErrorMessage = "Path not found"
        }
    } catch {
        $result.ErrorMessage = $_.Exception.Message
    }
    
    return $result
}

function Get-FileStatistics {
    <#
    .SYNOPSIS
    Generates statistics for files in a directory
    #>
    param(
        [string]$Path = ".",
        [switch]$Recurse
    )
    
    $stats = @{
        TotalFiles = 0
        TotalFolders = 0
        TotalSize = 0
        LargestFile = ""
        LargestFileSize = 0
        OldestFile = ""
        OldestFileDate = $null
        NewestFile = ""
        NewestFileDate = $null
        ErrorMessage = ""
        FileTypes = @{}
    }
    
    try {
        $params = @{
            Path = $Path
            ErrorAction = 'SilentlyContinue'
        }
        if ($Recurse) { $params.Recurse = $true }
        
        $items = Get-ChildItem @params
        
        $files = $items | Where-Object { $_ -is [System.IO.FileInfo] }
        $folders = $items | Where-Object { $_ -is [System.IO.DirectoryInfo] }
        
        $stats.TotalFiles = $files.Count
        $stats.TotalFolders = $folders.Count
        
        if ($files) {
            $stats.TotalSize = ($files | Measure-Object -Property Length -Sum).Sum
            
            $largest = $files | Sort-Object -Property Length -Descending | Select-Object -First 1
            if ($largest) {
                $stats.LargestFile = $largest.Name
                $stats.LargestFileSize = $largest.Length
            }
            
            $oldest = $files | Sort-Object -Property CreationTime | Select-Object -First 1
            if ($oldest) {
                $stats.OldestFile = $oldest.Name
                $stats.OldestFileDate = $oldest.CreationTime
            }
            
            $newest = $files | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
            if ($newest) {
                $stats.NewestFile = $newest.Name
                $stats.NewestFileDate = $newest.CreationTime
            }
            
            $files | Group-Object -Property Extension | ForEach-Object {
                $stats.FileTypes[$_.Name] = $_.Count
            }
        }
    } catch {
        $stats.ErrorMessage = $_.Exception.Message
    }
    
    return $stats
}

function Find-DuplicateFiles {
    <#
    .SYNOPSIS
    Finds duplicate files based on hash
    #>
    param(
        [string]$Path = ".",
        [switch]$Recurse
    )
    
    $params = @{
        Path = $Path
        File = $true
        ErrorAction = 'SilentlyContinue'
    }
    if ($Recurse) { $params.Recurse = $true }
    
    $files = Get-ChildItem @params
    $hashes = @{}
    $duplicates = @()
    
    foreach ($file in $files) {
        try {
            $hash = (Get-FileHash -Path $file.FullName -ErrorAction Stop).Hash
            
            if ($hashes.ContainsKey($hash)) {
                $duplicates += @{
                    Hash = $hash
                    OriginalFile = $hashes[$hash]
                    DuplicateFile = $file.FullName
                }
            } else {
                $hashes[$hash] = $file.FullName
            }
        } catch {
            # Skip files that can't be hashed
        }
    }
    
    return $duplicates
}

# ============================================================================
# MENU FUNCTIONS
# ============================================================================

function Show-MainMenu {
    Clear-HostSafe
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     FILE & FOLDER ORGANIZER & ASSERTION TOOL      ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Check Path Existence" -ForegroundColor White
    Write-Host "  2. View File Properties" -ForegroundColor White
    Write-Host "  3. View Folder Properties" -ForegroundColor White
    Write-Host "  4. Get File Statistics" -ForegroundColor White
    Write-Host "  5. Find Duplicate Files" -ForegroundColor White
    Write-Host "  6. Check Disk Space" -ForegroundColor White
    Write-Host "  7. Organize Files" -ForegroundColor White
    Write-Host "  8. Test File Read Access" -ForegroundColor White
    Write-Host "  9. Exit" -ForegroundColor Yellow
    Write-Host ""
}

function Invoke-PathCheck {
    Clear-HostSafe
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           CHECK PATH EXISTENCE                     ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $path = Read-Host "Enter path to check"
    
    if ([string]::IsNullOrWhiteSpace($path)) {
        Write-Host "Invalid input." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    $result = Assert-PathExists -Path $path
    
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Green
    Write-Host "  Path: $($result.Path)"
    Write-Host "  Exists: $(if ($result.Exists) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($result.Exists) { 'Green' } else { 'Red' })
    if ($result.Exists) {
        Write-Host "  Type: $(if ($result.IsFile) { 'File' } else { 'Directory' })"
        Write-Host "  Full Path: $($result.FullPath)"
    }
    if ($result.ErrorMessage) {
        Write-Host "  Error: $($result.ErrorMessage)" -ForegroundColor Red
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Invoke-FilePropertiesCheck {
    Clear-HostSafe
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           FILE PROPERTIES CHECK                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $filePath = Read-Host "Enter file path"
    
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        Write-Host "Invalid input." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    $props = Assert-FileProperties -FilePath $filePath
    
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Green
    Write-Host "  Exists: $(if ($props.Exists) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($props.Exists) { 'Green' } else { 'Red' })
    
    if ($props.Exists) {
        Write-Host "  Name: $($props.Name)"
        Write-Host "  Extension: $($props.Extension)"
        Write-Host "  Size: $(Format-Size $props.Size)"
        Write-Host "  Created: $($props.CreatedTime)"
        Write-Host "  Modified: $($props.ModifiedTime)"
        Write-Host "  Last Accessed: $($props.AccessTime)"
        Write-Host "  Read-Only: $(if ($props.IsReadOnly) { 'Yes' } else { 'No' })"
        Write-Host "  Attributes: $($props.Attributes)"
    }
    if ($props.ErrorMessage) {
        Write-Host "  Error: $($props.ErrorMessage)" -ForegroundColor Red
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Invoke-FolderPropertiesCheck {
    Clear-HostSafe
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           FOLDER PROPERTIES CHECK                  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $folderPath = Read-Host "Enter folder path"
    
    if ([string]::IsNullOrWhiteSpace($folderPath)) {
        Write-Host "Invalid input." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host "Analyzing folder..." -ForegroundColor Yellow
    $props = Assert-FolderProperties -FolderPath $folderPath -Recurse
    
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Green
    Write-Host "  Exists: $(if ($props.Exists) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($props.Exists) { 'Green' } else { 'Red' })
    
    if ($props.Exists) {
        Write-Host "  Name: $($props.Name)"
        Write-Host "  Full Path: $($props.FullPath)"
        Write-Host "  Is Empty: $(if ($props.IsEmpty) { 'Yes' } else { 'No' })"
        Write-Host "  File Count: $($props.FileCount)"
        Write-Host "  Subfolder Count: $($props.SubFolderCount)"
        Write-Host "  Total Size: $(Format-Size $props.TotalSize)"
        Write-Host "  Created: $($props.CreatedTime)"
        Write-Host "  Modified: $($props.ModifiedTime)"
    }
    if ($props.ErrorMessage) {
        Write-Host "  Error: $($props.ErrorMessage)" -ForegroundColor Red
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Invoke-FileStatisticsCheck {
    Clear-HostSafe
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           FILE STATISTICS                          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $path = Read-Host "Enter directory path (default: current)"
    if ([string]::IsNullOrWhiteSpace($path)) { $path = "." }
    
    Write-Host "Analyzing directory..." -ForegroundColor Yellow
    $stats = Get-FileStatistics -Path $path -Recurse
    
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Green
    Write-Host "  Total Files: $($stats.TotalFiles)"
    Write-Host "  Total Folders: $($stats.TotalFolders)"
    Write-Host "  Total Size: $(Format-Size $stats.TotalSize)"
    
    if ($stats.LargestFile) {
        Write-Host "  Largest File: $($stats.LargestFile) ($(Format-Size $stats.LargestFileSize))"
    }
    if ($stats.OldestFile) {
        Write-Host "  Oldest File: $($stats.OldestFile) ($($stats.OldestFileDate))"
    }
    if ($stats.NewestFile) {
        Write-Host "  Newest File: $($stats.NewestFile) ($($stats.NewestFileDate))"
    }
    
    if ($stats.FileTypes.Count -gt 0) {
        Write-Host ""
        Write-Host "  File Types:" -ForegroundColor Yellow
        $stats.FileTypes.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
            Write-Host "    $($_.Key): $($_.Value) files"
        }
    }
    
    if ($stats.ErrorMessage) {
        Write-Host "  Error: $($stats.ErrorMessage)" -ForegroundColor Red
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Invoke-DuplicateFileCheck {
    Clear-HostSafe
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           FIND DUPLICATE FILES                     ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $path = Read-Host "Enter directory path (default: current)"
    if ([string]::IsNullOrWhiteSpace($path)) { $path = "." }
    
    Write-Host "Scanning for duplicates..." -ForegroundColor Yellow
    $duplicates = Find-DuplicateFiles -Path $path -Recurse
    
    Write-Host ""
    if ($duplicates.Count -eq 0) {
        Write-Host "No duplicate files found." -ForegroundColor Green
    } else {
        Write-Host "Found $($duplicates.Count) duplicate(s):" -ForegroundColor Yellow
        Write-Host ""
        $duplicates | ForEach-Object {
            Write-Host "  Hash: $($_.Hash)"
            Write-Host "    Original: $($_.OriginalFile)"
            Write-Host "    Duplicate: $($_.DuplicateFile)"
            Write-Host ""
        }
    }
    
    Read-Host "Press Enter to continue"
}

function Invoke-DiskSpaceCheck {
    Clear-HostSafe
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           CHECK DISK SPACE                         ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $path = Read-Host "Enter path (default: current)"
    if ([string]::IsNullOrWhiteSpace($path)) { $path = "." }
    
    $space = Assert-DriveSpace -Path $path
    
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Green
    Write-Host "  Drive: $($space.Drive)"
    Write-Host "  Total Size: $(Format-Size $space.TotalSize)"
    Write-Host "  Used Space: $(Format-Size $space.UsedSpace)"
    Write-Host "  Free Space: $(Format-Size $space.FreeSpace)"
    Write-Host "  Percent Used: $($space.PercentUsed)%"
    
    if ($space.ErrorMessage) {
        Write-Host "  Error: $($space.ErrorMessage)" -ForegroundColor Red
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Invoke-FileReadAccessCheck {
    Clear-HostSafe
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           TEST FILE READ ACCESS                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $filePath = Read-Host "Enter file path"
    
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        Write-Host "Invalid input." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    $result = Assert-FileReadable -FilePath $filePath
    
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Green
    Write-Host "  Path: $($result.Path)"
    Write-Host "  Readable: $(if ($result.IsReadable) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($result.IsReadable) { 'Green' } else { 'Red' })
    
    if ($result.ErrorMessage) {
        Write-Host "  Error: $($result.ErrorMessage)" -ForegroundColor Red
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Format-Size {
    <#
    .SYNOPSIS
    Formats bytes into human-readable size
    #>
    param([long]$Bytes)
    
    if ($Bytes -eq 0) { return "0 B" }
    
    $sizes = @("B", "KB", "MB", "GB", "TB")
    $order = 0
    while ($Bytes -ge 1024 -and $order -lt $sizes.Count - 1) {
        $order++
        $Bytes = $Bytes / 1024
    }
    
    return "{0:N2} {1}" -f $Bytes, $sizes[$order]
}

function Invoke-InteractiveMenu {
    <#
    .SYNOPSIS
    Main interactive menu loop
    #>
    while ($true) {
        Show-MainMenu
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" { Invoke-PathCheck }
            "2" { Invoke-FilePropertiesCheck }
            "3" { Invoke-FolderPropertiesCheck }
            "4" { Invoke-FileStatisticsCheck }
            "5" { Invoke-DuplicateFileCheck }
            "6" { Invoke-DiskSpaceCheck }
            "7" { Invoke-FileOrganization }
            "8" { Invoke-FileReadAccessCheck }
            "9" { 
                Write-Host "`nExiting..." -ForegroundColor Yellow
                return
            }
            default { Write-Host "Invalid option. Press Enter to try again." -ForegroundColor Red; Read-Host }
        }
    }
}

function Invoke-FileOrganization {
    <#
    .SYNOPSIS
    Interactive file organization menu
    #>
    Clear-HostSafe
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           ORGANIZE FILES                           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $source = Read-Host "Enter source directory (default: current)"
    if ([string]::IsNullOrWhiteSpace($source)) { $source = "." }
    
    Write-Host ""
    Write-Host "Organization modes:"
    Write-Host "  1. By Extension"
    Write-Host "  2. By Date (YYYY-MM)"
    Write-Host "  3. By File Type"
    Write-Host ""
    
    $modeChoice = Read-Host "Select organization mode"
    
    $mode = switch ($modeChoice) {
        "1" { "extension" }
        "2" { "date" }
        "3" { "type" }
        default { "extension" }
    }
    
    $dryRun = Read-Host "Run as dry-run? (y/n, default: y)"
    $isDryRun = $dryRun -ne "n"
    
    Write-Host ""
    Write-Host "Starting organization (Mode: $mode, Dry-Run: $(if ($isDryRun) { 'Yes' } else { 'No' }))..." -ForegroundColor Yellow
    Write-Host ""
    
    # Call the original organization logic
    Invoke-FileOrganizationLogic -Source $source -Mode $mode -DryRun $isDryRun
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Get-TypeFolder($ext) {
    switch ($ext) {
        ".jpg" { "Images" }
        ".png" { "Images" }
        ".gif" { "Images" }
        ".mp4" { "Video" }
        ".mkv" { "Video" }
        ".mp3" { "Audio" }
        ".flac" { "Audio" }
        ".pdf" { "Documents" }
        ".docx" { "Documents" }
        ".txt" { "Documents" }
        ".zip" { "Archives" }
        ".rar" { "Archives" }
        default { "Other" }
    }
}

function Invoke-FileOrganizationLogic {
    <#
    .SYNOPSIS
    Core file organization logic
    #>
    param(
        [string]$Source = ".",
        [string]$Mode = "extension",
        [switch]$DryRun = $false,
        [switch]$Recurse = $true,
        [switch]$HandleDuplicates = $true
    )
    
    Write-Log "==== Organizer start ===="
    Write-Log "Mode: $Mode | Source: $Source | DryRun: $DryRun"

    $files = Get-ChildItem -Path $Source -File -Recurse:$Recurse -ErrorAction SilentlyContinue

    foreach ($file in $files) {

        switch ($Mode) {

            "extension" {
                $folder = $file.Extension.TrimStart(".")
            }

            "date" {
                $folder = $file.LastWriteTime.ToString("yyyy-MM")
            }

            "type" {
                $folder = Get-TypeFolder $file.Extension.ToLower()
            }
        }

        $targetDir = Join-Path $Source $folder

        if (!(Test-Path $targetDir)) {
            if (!$DryRun) {
                New-Item -ItemType Directory -Path $targetDir | Out-Null
            }
        }

        $targetFile = Join-Path $targetDir $file.Name

        if ((Test-Path $targetFile) -and $HandleDuplicates) {
            $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $ext = $file.Extension
            $i = 1
            do {
                $targetFile = Join-Path $targetDir "$base`_$i$ext"
                $i++
            } until (!(Test-Path $targetFile))
        }

        if ($DryRun) {
            Write-Log "[DRYRUN] $($file.FullName) -> $targetFile"
        } else {
            Move-Item $file.FullName $targetFile
            Write-Log "Moved $($file.FullName) -> $targetFile"
        }
    }

    Write-Log "==== Organizer end ===="
}

# ============================================================================
# ENTRY POINT
# ============================================================================

if ($Interactive) {
    Invoke-InteractiveMenu
} else {
    Invoke-FileOrganizationLogic -Source $Source -Mode $Mode -DryRun $DryRun -Recurse $Recurse -HandleDuplicates $HandleDuplicates
}