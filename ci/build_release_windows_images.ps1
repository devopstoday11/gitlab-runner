Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
# ---------------------------------------------------------------------------
# This script depends on a few environment variables that should be populated
# before running the script:
#
# - $Env:WINDOWS_VERSION - This is the version of windows that is going to be
#   used for building the Docker image. It is important for the version to match
#   one of the mcr.microsoft.com/windows/servercore or https://hub.docker.com/_/microsoft-windows-nanoserver
#   tag prefixes (discarding the architecture suffix).
#   For example, `servercore1903` will build from mcr.microsoft.com/windows/servercore:1903-amd64.
# - $Env:GIT_VERSION - Specify which version of Git needs to be installed on
#   the Docker image. This is done through Docker build args.
# - $Env:GIT_VERSION_BUILD - Specify which build is needed to download for the
#   GIT_VERSION you specified.
# - $Env:GIT_256_CHECKSUM - The checksum of the downloaded zip, usually found in
#   the GitHub release page.
# - $Env:GIT_LFS_VERSION - The Git LFS version needed to install on the
#   Docker image.
# - $Env:GIT_LFS_256_CHECKSUM - The checksum of the downloaded zip, usually
#   found in the GitHub release page.
# - $Env:IS_LATEST - When we want to tag current tag as the latest, this is usually
#   used when we are tagging a release for the runner (which is not a patch
#   release or RC)
# - $Env:DOCKER_HUB_USER - The user we want to login with for docker hub.
# - $Env:DOCKER_HUB_PASSWORD - The password we want to login with for docker hub.
# - $Env:PUSH_TO_DOCKER_HUB - If set to true, it will login to the registry and
#   push the tags.
# - $Env:SKIP_CLEANUP - By default this PowerShell script will delete the image
#   it just build.
# - $Env:DOCKER_HUB_NAMESPACE - Usually empty and only set for development, to
#   use your own namespace instead of `gitlab`.
# - $Env:CI_REGISTRY_IMAGE - Image name to push to GitLab registry. Usually set
#   by CI.
# - $Env:CI_REGISTRY - The GitLab registry name. Usually set by CI.
# - $Env:CI_REGISTRY_USER - The user used to login CI_REGISTRY. Usually set by
#   CI.
# - $Env:CI_REGISTRY_PASSWORD - The password used to login CI_REGISTRY. Usually
#   set by CI.
# ---------------------------------------------------------------------------
$imagesBasePath = "dockerfiles/runner-helper/Dockerfile.x86_64"

function Main
{
    $tag = Get-Tag

    Build-Image $tag

    if ($Env:PUSH_TO_DOCKER_HUB -eq "true")
    {
        $namespace = DockerHub-Namespace

        Connect-Registry $Env:DOCKER_HUB_USER $Env:DOCKER_HUB_PASSWORD
        Push-Tag $namespace $tag

        if ($Env:IS_LATEST -eq "true")
        {
            Add-LatestTag $namespace $tag
            Push-Latest $namespace
        }

        Disconnect-Registry
    }

    if ($Env:PUBLISH_IMAGES -eq "true")
    {
        Connect-Registry $Env:CI_REGISTRY_USER $Env:CI_REGISTRY_PASSWORD $Env:CI_REGISTRY

        Push-Tag "${Env:CI_REGISTRY_IMAGE}" $tag

        if ($Env:IS_LATEST -eq "true")
        {
            Add-LatestTag $Env:CI_REGISTRY_IMAGE $tag
            Push-Latest $Env:CI_REGISTRY_IMAGE
        }

        Disconnect-Registry $env:CI_REGISTRY
    }
}

function Get-Tag
{
    $revision = & 'git' rev-parse --short=8 HEAD

    return "x86_64-$revision-$Env:WINDOWS_VERSION"
}

function Build-Image($tag)
{
    $windowsFlavor = $env:WINDOWS_VERSION.Substring(0, $env:WINDOWS_VERSION.length -4)
    $windowsVersion = $env:WINDOWS_VERSION.Substring($env:WINDOWS_VERSION.length -4)
    $dockerHubNamespace = DockerHub-Namespace

    Write-Information "Build image for x86_64_${env:WINDOWS_VERSION}"

    $dockerFile = "${imagesBasePath}_${windowsFlavor}"
    $context = "dockerfiles/runner-helper"
    New-Item -ItemType Directory -Force -Path $context\binaries
    Copy-Item -Path "out\binaries\gitlab-runner-helper\gitlab-runner-helper.x86_64-windows.exe" -Destination "$context/binaries"
    $buildArgs = @(
        '--build-arg', "BASE_IMAGE_TAG=mcr.microsoft.com/windows/${windowsFlavor}:${windowsVersion}-amd64",
        '--build-arg', "PWSH_VERSION=$Env:PWSH_VERSION",
        '--build-arg', "PWSH_256_CHECKSUM=$Env:PWSH_256_CHECKSUM",
        '--build-arg', "GIT_VERSION=$Env:GIT_VERSION",
        '--build-arg', "GIT_VERSION_BUILD=$Env:GIT_VERSION_BUILD",
        '--build-arg', "GIT_256_CHECKSUM=$Env:GIT_256_CHECKSUM"
        '--build-arg', "GIT_LFS_VERSION=$Env:GIT_LFS_VERSION"
        '--build-arg', "GIT_LFS_256_CHECKSUM=$Env:GIT_LFS_256_CHECKSUM"
    )

    $imageNames = @(
        '-t', "$dockerHubNamespace/gitlab-runner-helper:$tag",
        '-t', "$Env:CI_REGISTRY_IMAGE/gitlab-runner-helper:$tag"
    )

    & 'docker' build $imageNames --force-rm --no-cache $buildArgs -f $dockerFile $context
    if ($LASTEXITCODE -ne 0) {
        throw ("Failed to build docker image" )
    }
}

function Push-Tag($namespace, $tag)
{
    Write-Information "Push $tag"

    & 'docker' push ${namespace}/gitlab-runner-helper:$tag
    if ($LASTEXITCODE -ne 0) {
        throw ("Failed to push docker image ${namespace}/gitlab-runner-helper:$tag" )
    }
}

function Add-LatestTag($namespace, $tag)
{
    Write-Information "Tag $tag as latest"

    & 'docker' tag "${namespace}/gitlab-runner-helper:$tag" "${namespace}/gitlab-runner-helper:x86_64-latest-$Env:WINDOWS_VERSION"
    if ($LASTEXITCODE -ne 0) {
        throw ("Failed to tag ${namespace}/gitlab-runner-helper:$tag as latest image" )
    }
}

function Push-Latest($namespace)
{
    Write-Information "Push latest tag"

    & 'docker' push "${namespace}/gitlab-runner-helper:x86_64-latest-$Env:WINDOWS_VERSION"
    if ($LASTEXITCODE -ne 0) {
        throw ("Failed to push image to registry" )
    }
}

function Connect-Registry($username, $password, $registry)
{
    Write-Information "Login registry $registry"

    & 'docker' login --username $username --password $password $registry
    if ($LASTEXITCODE -ne 0) {
        throw ("Failed to login Docker hub" )
    }
}

function Disconnect-Registry($registry)
{
    Write-Information "Logout registry $registry"

    & 'docker' logout $registry
    if ($LASTEXITCODE -ne 0) {
        throw ("Failed to logout from Docker hub" )
    }
}

function DockerHub-Namespace
{
    if(-not (Test-Path env:DOCKER_HUB_NAMESPACE))
    {
        return "gitlab"
    }

    return $Env:DOCKER_HUB_NAMESPACE
}

Try
{
    if (-not (Test-Path env:WINDOWS_VERSION))
    {
        throw '$Env:WINDOWS_VERSION is not set'
    }

    Main
}
Finally
{
    if (-not (Test-Path env:SKIP_CLEANUP))
    {
        Write-Information "Cleaning up the build image"
        $tag = Get-Tag
        $dockerHubNamespace = DockerHub-Namespace

        # We don't really care if these fail or not, clean up shouldn't fail
        # the pipelines.
        & 'docker' rmi -f $dockerHubNamespace/gitlab-runner-helper:$tag
        & 'docker' rmi -f $Env:CI_REGISTRY_IMAGE/gitlab-runner-helper:$tag
        & 'docker' image prune -f
    }
}
