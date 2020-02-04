# $ErrorActionPreference = "Stop";
# $InformationPreference = "Continue";


function Deploy-BlazorGhPages {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$ProjectPath,
    [Parameter(Mandatory = $true)][string]$GhPagesRoute
  )

  $rootAbsolutePath = (Get-Location).ToString();

  Write-Verbose('Blazor Project Path: ' + $rootAbsolutePath + '/' + $ProjectPath);
  Write-Verbose('GitHub Pages route: ' + '/' + $GhPagesRoute + '/');

  $GitHubRepoUrl; # declare the variable, do I even need it? scope? 
  $repoOriginUrl = git config --get remote.origin.url;
  if ($repoOriginUrl -like '*github.com*') {
    $GitHubRepoUrl = $repoOriginUrl;
    Write-Verbose('GitHub Repo URL: ' + $GitHubRepoUrl);
  }
  else {
    throw 'git.remote.origin is not GitHub.';
  }

  $tempFolderName = "_temp_deploy_ghpages";
  if (-Not (Test-Path -Path $tempFolderName -PathType Container)) {
    New-Item -Path $tempFolderName -ItemType Directory;
    Write-Verbose "Created a $tempFolderName folder.";
  }
  else {
    throw "Folder $tempFolderName already exists."
  }

  dotnet publish --configuration Release --output $tempFolderName;

  $distFolderRelativePath = $tempFolderName + "\" + $ProjectPath + "\dist";
  if (-Not (Test-Path -Path $distFolderRelativePath -PathType Container)) {
    throw "Folder $distFolderRelativePath doesn't exists.";
  }
  else {
    # Write-Verbose "Folder $distFolderRelativePath exists.";
  }

  $repoFolderName = "_temp_repo";
  $repoFolderRelativePath = $tempFolderName + "\" + $repoFolderName;
  New-Item -Path $repoFolderRelativePath -ItemType Directory;

  Set-Location $repoFolderRelativePath;

  git init
  git remote add origin $GitHubRepoUrl
  git checkout -b master
  git pull origin gh-pages
  # git checkout -b gh-pages
  git checkout gh-pages
  # git push origin --delete gh-pages

  Remove-Item -path * -exclude .git -recurse;

  Set-Location $rootAbsolutePath;

  # Copy the files to the temporary "repo" folder:
  Copy-Item -Path $distFolderRelativePath"\*" -Destination $repoFolderRelativePath -Recurse
  Write-Verbose "Copied the files to $repoFolderRelativePath.";

  $IndexHtmlRelativePath = $repoFolderRelativePath + "\index.html";
  if (Test-Path -Path $IndexHtmlRelativePath) {
    Write-Verbose "$IndexHtmlRelativePath exists.";

    (Get-Content -Path $IndexHtmlRelativePath) |
    ForEach-Object { 
      $_ -replace ('<base href="/" />', ('<base href="/' + $GhPagesRoute + '/" />'));
    } |
    Set-Content -Path $IndexHtmlRelativePath;
    Write-Verbose "Modified the <base /> in index.html.";

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
    Write-Verbose "Added the <script /> to index.html.";
  }

  New-Item -Path $repoFolderRelativePath -ItemType File -Name ".nojekyll"
  Write-Verbose "Created the .nojekyll file.";

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
  Write-Verbose "Created the 404.html file.";

  Set-Location $repoFolderRelativePath;

  git add .
  git commit -m "Deploy to GitHub Pages."
  git push
  # git push --set-upstream origin gh-pages

  # Add-Content -Path "404.html" -Value " "
  # git add .
  # git commit -m "A quick fix."
  # git push

  Set-Location $rootAbsolutePath;
  Remove-Item -Path $rootAbsolutePath"\"$tempFolderName -Recurse -Force;
}