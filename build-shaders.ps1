# Define the input and output directories
$InputDir = "./res/shaders_pre"
$OutputDir = "./src/shaders"

# Check if sokol-shdc.exe exists in the current directory
if (-not (Test-Path ".\sokol-shdc.exe")) {
    Write-Error "sokol-shdc.exe not found in the current directory."
    exit 1
}

# Ensure the output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}


# Process each .glsl file in the input directory
Get-ChildItem -Path $InputDir -Filter "*.glsl" | ForEach-Object {
    $InputFile = $_.FullName
    $OutputFile = Join-Path $OutputDir ($_.BaseName + ".glsl.zig")

    # Run sokol-shdc.exe command
    Write-Host "Processing: $InputFile"
    $Command = "sokol-shdc.exe --input `"$InputFile`" --output `"$OutputFile`" --slang hlsl5:glsl430:metal_macos -f sokol_zig"
    & cmd /c $Command

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error processing $InputFile"
        exit $LASTEXITCODE
    }
}


Write-Host "All files processed successfully."