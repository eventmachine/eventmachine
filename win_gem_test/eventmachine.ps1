# PowerShell script for building & testing EventMachine pre-compiled gem
# builds EM with ssl support
# Code by MSP-Greg, see https://github.com/MSP-Greg/av-gem-build-test

# load utility functions, pass 64 or 32
. $PSScriptRoot\shared\appveyor_setup.ps1 $args[0]
if ($LastExitCode) { exit }

# above is required code
#———————————————————————————————————————————————————————————————— above for all repos

Make-Const gem_name  'eventmachine'
Make-Const repo_name 'eventmachine'
Make-Const url_repo  'https://github.com/eventmachine/eventmachine.git'

#———————————————————————————————————————————————————————————————— lowest ruby version
Make-Const ruby_vers_low 22
# null = don't compile; false = compile, ignore test (allow failure);
# true = compile & test
Make-Const trunk     $null  ; Make-Const trunk_x64     $null
Make-Const trunk_JIT $null  ; Make-Const trunk_x64_JIT $null

#———————————————————————————————————————————————————————————————— make info
Make-Const dest_so  'lib'
Make-Const exts     @(
  @{ 'conf' = 'ext/extconf.rb'                ; 'so' = 'rubyeventmachine'  },
  @{ 'conf' = 'ext/fastfilereader/extconf.rb' ; 'so' = 'fastfilereaderext' }
)
Make-Const write_so_require $true

# $msys_full = $true    # Uncomment for full msys2 update

#———————————————————————————————————————————————————————————————— pre compile
# runs before compiling starts on every ruby version
function Pre-Compile {
  Check-OpenSSL
  Write-Host Compiling With $env:SSL_VERS
}

#———————————————————————————————————————————————————————————————— Run-Tests
function Run-Tests {
  # call with comma separated list of gems to install or update
  Update-Gems rake, test-unit
  rake -f Rakefile_wintest -N -R norakelib | Set-Content -Path $log_name -PassThru -Encoding UTF8
  # add info after test results
  $(ruby -ropenssl -e "STDOUT.puts $/ + OpenSSL::OPENSSL_LIBRARY_VERSION") |
    Add-Content -Path $log_name -PassThru -Encoding UTF8
  test_unit
}

#———————————————————————————————————————————————————————————————— below for all repos
# below is required code

Make-Const dir_gem  $(Convert-Path $PSScriptRoot\..)
Make-Const dir_ps   $PSScriptRoot

Push-Location $PSScriptRoot
.\shared\make.ps1
.\shared\test.ps1
Pop-Location
exit $ttl_errors_fails + $exit_code
