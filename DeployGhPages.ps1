$ErrorActionPreference = "Stop";
$InformationPreference = "Continue";

# SPECIFY THE FOLLOWING:
$BlazorWasmProjectName = "DeployGhPages.Client"; #project name from the solution ().sln file).
# It's the folder's name in the $tempFolderName folder.

$GitHubProjectName = "BlazorWasm-DeployGhPages"; # for the base route in index.html.

$GitHubRepoUrl = "https://github.com/dima-iholkin/BlazorWasm-DeployGhPages.git";



$tempFolderName = "_temp-DeployGhPages";
if (-Not (Test-Path -Path $tempFolderName -PathType Container)) {
  New-Item -Path $tempFolderName -ItemType Directory;
  Write-Information "";
  Write-Information "INFO: Created a $tempFolderName folder.";
  Write-Information "";
}

dotnet publish --configuration Release --output $tempFolderName;

$distFolderRelativePath = $tempFolderName + "\" + $BlazorWasmProjectName + "\dist";
if (Test-Path -Path $distFolderRelativePath -PathType Container) {
  Write-Information "";
  Write-Information "INFO: The folder $distFolderRelativePath exists.";
}
else {
  throw "The folder $distFolderRelativePath doesn't exists.";
}

# Copy the files to the temporary "repo" folder:
$repoFolderName = "_repo";
$repoFolderRelativePath = $tempFolderName + "\" + $repoFolderName;
New-Item -Path $repoFolderRelativePath -ItemType Directory;
Copy-Item -Path $distFolderRelativePath"\*" -Destination $repoFolderRelativePath -Recurse
Write-Information "";
Write-Information "INFO: Copied the files to $repoFolderRelativePath.";

$IndexHtmlRelativePath = $repoFolderRelativePath + "\index.html";
if (Test-Path -Path $IndexHtmlRelativePath) {
  Write-Information "";
  Write-Information "INFO: $IndexHtmlRelativePath exists.";

  (Get-Content -Path $IndexHtmlRelativePath) |
  ForEach-Object { 
    $_ -replace ('<base href="/" />', ('<base href="/' + $GitHubProjectName + '/" />'));
  } |
  Set-Content -Path $IndexHtmlRelativePath;
  Write-Information "";
  Write-Information "INFO: Modified the <base /> in index.html.";

  (Get-Content -Path $IndexHtmlRelativePath) |
  ForEach-Object { 
    $_
    if ($_ -match '<app>Loading...</app>') {
      @'

    <!-- Start Single Page Apps for GitHub Pages -->
    <script type="text/javascript">
        // Single Page Apps for GitHub Pages
        // https://github.com/rafrex/spa-github-pages
        // Copyright (c) 2016 Rafael Pedicini, licensed under the MIT License
        // ----------------------------------------------------------------------
        // This script checks to see if a redirect is present in the query string
        // and converts it back into the correct url and adds it to the
        // browser's history using window.history.replaceState(...),
        // which won't cause the browser to attempt to load the new url.
        // When the single page app is loaded further down in this file,
        // the correct url will be waiting in the browser's history for
        // the single page app to route accordingly.
        (function (l) {
            if (l.search) {
                var q = {};
                l.search.slice(1).split('&').forEach(function (v) {
                    var a = v.split('=');
                    q[a[0]] = a.slice(1).join('=').replace(/~and~/g, '&');
                });
                if (q.p !== undefined) {
                    window.history.replaceState(null, null,
                        l.pathname.slice(0, -1) + (q.p || '') +
                        (q.q ? ('?' + q.q) : '') +
                        l.hash
                    );
                }
            }
        }(window.location))
    </script>
    <!-- End Single Page Apps for GitHub Pages -->
'@
    }
  } |
  Set-Content -Path $IndexHtmlRelativePath;
  Write-Information "";
  Write-Information "INFO: Added the <script /> to index.html.";
}

New-Item -Path $repoFolderRelativePath -ItemType File -Name ".nojekyll"
Write-Information "";
Write-Information "INFO: Created the .nojekyll file.";

New-Item -Path $repoFolderRelativePath -ItemType File -Name "404.html" | 
Add-Content -Value @'
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Single Page Apps for GitHub Pages</title>
    <script type="text/javascript">
      // Single Page Apps for GitHub Pages
      // https://github.com/rafrex/spa-github-pages
      // Copyright (c) 2016 Rafael Pedicini, licensed under the MIT License
      // ----------------------------------------------------------------------
      // This script takes the current url and converts the path and query
      // string into just a query string, and then redirects the browser
      // to the new url with only a query string and hash fragment,
      // e.g. http://www.foo.tld/one/two?a=b&c=d#qwe, becomes
      // http://www.foo.tld/?p=/one/two&q=a=b~and~c=d#qwe
      // Note: this 404.html file must be at least 512 bytes for it to work
      // with Internet Explorer (it is currently > 512 bytes)
      // If you're creating a Project Pages site and NOT using a custom domain,
      // then set segmentCount to 1 (enterprise users may need to set it to > 1).
      // This way the code will only replace the route part of the path, and not
      // the real directory in which the app resides, for example:
      // https://username.github.io/repo-name/one/two?a=b&c=d#qwe becomes
      // https://username.github.io/repo-name/?p=/one/two&q=a=b~and~c=d#qwe
      // Otherwise, leave segmentCount as 0.
      var segmentCount = 0;
      var l = window.location;
      l.replace(
        l.protocol + '//' + l.hostname + (l.port ? ':' + l.port : '') +
        l.pathname.split('/').slice(0, 1 + segmentCount).join('/') + '/?p=/' +
        l.pathname.slice(1).split('/').slice(segmentCount).join('/').replace(/&/g, '~and~') +
        (l.search ? '&q=' + l.search.slice(1).replace(/&/g, '~and~') : '') +
        l.hash
      );
    </script>
  </head>
  <body>
  </body>
</html>
'@;
Write-Information "";
Write-Information "INFO: Created the 404.html file.";

$rootAbsolutePath = (Get-Location).ToString();

Set-Location $repoFolderRelativePath;

git init
git remote add origin $GitHubRepoUrl;
git checkout -b gh-pages
git pull
# git push origin --delete gh-pages
git add .
git commit -m "Delpoy to GitHub Pages."
git push --set-upstream origin gh-pages



# Write-Output("pathToNewDirRoot: " + $pathToNewDir);

# $objTempRepo = New-Item -Name "_temprepo" -ItemType "Directory";
# $pathToTempRepo = $objTempRepo.FullName;
# Set-Location -Path $pathToTempRepo
# Write-Output("pathToTempRepo: " + $pathToTempRepo);

# git init
# Copy-Item -Path $pathToNewDirDeployFiles"\*" -Destination $pathToTempRepo.ToString() -Recurse
# git remote add origin https://github.com/dima-iholkin/Demo_Blazor.git
# git push origin --delete gh-pages
# git checkout -b gh-pages
# git add .
# git commit -m "Delpoy to GitHub Pages."
# git push --set-upstream origin gh-pages

# Add-Content -Path "404.html" -Value " "
# git add .
# git commit -m "Maybe it will help."
# git push

# Set-Location $pathToOriginalRepo


Set-Location $rootAbsolutePath;
Remove-Item -Path $rootAbsolutePath"\"$tempFolderName -Recurse -Force;



# $deploymentFolderName = "DeployGhPages";
# $deploymentFolderRelativePath = $tempFolderName + "\" + $deploymentFolderName;
# if (-Not (Test-Path -Path $deploymentFolderRelativePath -PathType Container )) {
#   New-Item -Path $deploymentFolderRelativePath -ItemType Directory;
#   Write-Output "Created a $deploymentFolderName folder.";
# }

# $tempFolder = $env:TEMP;

# $isDevelopment = $TRUE;

# if ($isDevelopment) {
#   $tempFolder = Get-Location;
# } else {
#   $tempFolder = $env:TEMP;
# }

# Write-Output("Temp folder: " + $tempFolder);

# $newFolderName = "deploy-gh-pages";

# if ( Test-Path -Path $tempFolder"\"$newFolderName) {
#   Remove-Item $tempFolder"\"$newFolderName -Recurse -Force;
# }

<#
$objNewDir = New-Item -Path $tempFolder -Name $newFolderName -ItemType "Directory";
$pathToNewDir = $objNewDir.FullName;

dotnet publish --configuration Release --output $pathToNewDir;

# $objNewDir_Temp = New-Item -Path $pathToNewDir -Name "_temp" -ItemType "Directory";
# $pathToNewDir_Temp = $objNewDir_Temp.FullName;

$pathToNewDirDeployFiles = $pathToNewDir + "\Blazor.Client\dist";
# Write-Output("Deploy Files folder: " + $pathToNewDirDeployFiles);
# Get-ChildItem -Path $pathToNewDirDeployFiles;

$pathToIndexHtml = $pathToNewDirDeployFiles + "\index.html";

# (Get-Content -Path $pathToIndexHtml) |
# ForEach-Object {
#   if ($_ -match '<base href="/" />') { 
#     # Write-Output("hello there");
#     # Write-Output($_);
#     # $_ -replace "href", "hello";
#     # $_ -replace '<base href="/" />', '<base href="/Demo_Blazor/" />' 
#   } 
# } |
# Set-Content -Path $pathToIndexHtml;

(Get-Content -Path $pathToIndexHtml) |
ForEach-Object { 
  $_ -replace ('<base href="/" />', '<base href="/Demo_Blazor/" />');
} |
Set-Content -Path $pathToIndexHtml;

# Get-Content -Path $pathToIndexHtml |
# ForEach-Object {
#     if($_ -match "Normal") { $_ -replace "Normal", "Rollout"} 
#     elseif($_ -match "Rollout") { $_ -replace "Rollout", "Normal"}
# } | 
# Set-Content C:\temp\a.html

(Get-Content -Path $pathToIndexHtml) |
ForEach-Object { 
  $_
  if ($_ -match '<app>Loading...</app>') {
    @'

    <!-- Start Single Page Apps for GitHub Pages -->
    <script type="text/javascript">
        // Single Page Apps for GitHub Pages
        // https://github.com/rafrex/spa-github-pages
        // Copyright (c) 2016 Rafael Pedicini, licensed under the MIT License
        // ----------------------------------------------------------------------
        // This script checks to see if a redirect is present in the query string
        // and converts it back into the correct url and adds it to the
        // browser's history using window.history.replaceState(...),
        // which won't cause the browser to attempt to load the new url.
        // When the single page app is loaded further down in this file,
        // the correct url will be waiting in the browser's history for
        // the single page app to route accordingly.
        (function (l) {
            if (l.search) {
                var q = {};
                l.search.slice(1).split('&').forEach(function (v) {
                    var a = v.split('=');
                    q[a[0]] = a.slice(1).join('=').replace(/~and~/g, '&');
                });
                if (q.p !== undefined) {
                    window.history.replaceState(null, null,
                        l.pathname.slice(0, -1) + (q.p || '') +
                        (q.q ? ('?' + q.q) : '') +
                        l.hash
                    );
                }
            }
        }(window.location))
    </script>
    <!-- End Single Page Apps for GitHub Pages -->
'@
  }
} |
Set-Content -Path $pathToIndexHtml;

New-Item -Path $pathToNewDirDeployFiles -ItemType File -Name ".nojekyll"

New-Item -Path $pathToNewDirDeployFiles -ItemType File -Name "404.html" | 
Add-Content -Value @'
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Single Page Apps for GitHub Pages</title>
    <script type="text/javascript">
      // Single Page Apps for GitHub Pages
      // https://github.com/rafrex/spa-github-pages
      // Copyright (c) 2016 Rafael Pedicini, licensed under the MIT License
      // ----------------------------------------------------------------------
      // This script takes the current url and converts the path and query
      // string into just a query string, and then redirects the browser
      // to the new url with only a query string and hash fragment,
      // e.g. http://www.foo.tld/one/two?a=b&c=d#qwe, becomes
      // http://www.foo.tld/?p=/one/two&q=a=b~and~c=d#qwe
      // Note: this 404.html file must be at least 512 bytes for it to work
      // with Internet Explorer (it is currently > 512 bytes)
      // If you're creating a Project Pages site and NOT using a custom domain,
      // then set segmentCount to 1 (enterprise users may need to set it to > 1).
      // This way the code will only replace the route part of the path, and not
      // the real directory in which the app resides, for example:
      // https://username.github.io/repo-name/one/two?a=b&c=d#qwe becomes
      // https://username.github.io/repo-name/?p=/one/two&q=a=b~and~c=d#qwe
      // Otherwise, leave segmentCount as 0.
      var segmentCount = 0;
      var l = window.location;
      l.replace(
        l.protocol + '//' + l.hostname + (l.port ? ':' + l.port : '') +
        l.pathname.split('/').slice(0, 1 + segmentCount).join('/') + '/?p=/' +
        l.pathname.slice(1).split('/').slice(segmentCount).join('/').replace(/&/g, '~and~') +
        (l.search ? '&q=' + l.search.slice(1).replace(/&/g, '~and~') : '') +
        l.hash
      );
    </script>
  </head>
  <body>
  </body>
</html>
'@;

Get-ChildItem -Path $pathToNewDirDeployFiles;

$pathToOriginalRepo = (Get-Location).ToString();

Set-Location $pathToNewDir;
Write-Output("pathToNewDirRoot: " + $pathToNewDir);

$objTempRepo = New-Item -Name "_temprepo" -ItemType "Directory";
$pathToTempRepo = $objTempRepo.FullName;
Set-Location -Path $pathToTempRepo
Write-Output("pathToTempRepo: " + $pathToTempRepo);

git init
Copy-Item -Path $pathToNewDirDeployFiles"\*" -Destination $pathToTempRepo.ToString() -Recurse
git remote add origin https://github.com/dima-iholkin/Demo_Blazor.git
git push origin --delete gh-pages
git checkout -b gh-pages
git add .
git commit -m "Delpoy to GitHub Pages."
git push --set-upstream origin gh-pages

Add-Content -Path "404.html" -Value " "
git add .
git commit -m "Maybe it will help."
git push

Set-Location $pathToOriginalRepo

Remove-Item $tempFolder"\"$newFolderName -Recurse -Force;
#>