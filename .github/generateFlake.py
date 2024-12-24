import subprocess
import pathlib
import sys
from typing import Iterable, TypedDict

def prefetch(url: str):
    print("Fetching URL:", url)
    
    res = subprocess.run(["nix-prefetch-url", f"{url}", "--unpack"], capture_output=True, text=True)
    
    print("Errors:", res.stderr, "\nSTDOUT:", res.stdout)
    
    return res.stdout.splitlines()[0].strip()

def getSHA256s(urls: Iterable[str]) -> tuple[str,]:
    return (prefetch(url) for url in urls)

def getTemplate():
    flakeTemplatePath = pathlib.Path("flake.template.nix")
    flakeTemplateFile = open(file=flakeTemplatePath, mode="r")
    flakeTemplate = flakeTemplateFile.read()
    return flakeTemplate


class Variant(TypedDict):
    name: str
    url: str
    sha256: str

def generateFlakeContent(
    template: str, 
    version: str, 
    variants: Iterable[Variant],
    ):
    toReplace = {
        "%VERSION%": version,
    }
    
    for variant in variants:
        toReplace[f"%{variant['name']}_URL%"] = variant["url"]
        toReplace[f"%{variant['name']}_SHA256%"] = variant["sha256"]

    flakeContent = template

    for key, value in toReplace.items():
        flakeContent = flakeContent.replace(key, value)
    
    return flakeContent

def generateFlake(version: str):
    urls = {
    "x86_64": f"https://github.com/zen-browser/desktop/releases/download/{version}/zen.linux-x86_64.tar.bz2",
    "aarch64": f"https://github.com/zen-browser/desktop/releases/download/{version}/zen.linux-aarch64.tar.bz2"
    }
    
    x86_64HASH, aarch64HASH  = getSHA256s(urls.values())
    
    variants = (
        Variant(name="x86_64", url=urls["x86_64"], sha256=x86_64HASH),
        Variant(name="aarch64", url=urls["aarch64"], sha256=aarch64HASH)
    )
    
    flakeTemplate = getTemplate()
    flakeContent = generateFlakeContent(
        template=flakeTemplate, 
        version=version, 
        variants=variants,
    ) 
    
    # WRITE TO FLAXE.NIX
    flakePath = pathlib.Path("flake.nix")
    flakePath.touch()
    flakeFile = open(file=flakePath, mode="w")
    flakeFile.write(flakeContent)


if __name__ == "__main__":
    generateFlake(version=sys.argv[1])