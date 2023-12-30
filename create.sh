#!/bin/bash
DATE=`date +%m-%d-%Y`
DOWNLOAD=download
REPOS=repos
FOLDERNAME=SD_card

cleanup () {
    rm -rf $FOLDERNAME
    rm -rf $DOWNLOAD
}

cleanup

#create folders
mkdir $FOLDERNAME
mkdir $FOLDERNAME/mos
mkdir $FOLDERNAME/utils
mkdir $FOLDERNAME/games
mkdir $FOLDERNAME/games/sokoban
mkdir $FOLDERNAME/docs


latest_url() {
    curl -s "https://api.github.com/repos/$1/releases/latest" \
    | grep "browser_download_url.*$2" \
    | cut -d : -f 2,3 \
    | tr -d \"
}

download_latest() {
    echo "Downloading $2 from latest release of $1..."
    curl -sLO $(latest_url "$1" "$2")
}

git_clone() {
    echo "Cloning $1..."
    git clone -q "https://github.com/$1.git"
}

git_pull() {
    echo "Pulling $1..."
    cd $(basename $1)
    #git pull -q
    cd ..
}

crc32() {
    cat "$1" | gzip -1 -c | tail -c8 | xxd -p
}

#Download full repos

GITHUB_REPOS="
    breakintoprogram/agon-vdp
    breakintoprogram/agon-mos
    breakintoprogram/agon-bbc-basic
    breakintoprogram/agon-docs.wiki
    lennart-benschop/agon-utilities
    lennart-benschop/agon-forth
    sijnstra/agon-projects
    envenomator/agon-sokoban
    nihirash/Agon-rokky
    tomm/toms-agon-experiments
"

mkdir -p $REPOS
cd $REPOS
for repo in $GITHUB_REPOS; do
    if [[ -n $repo ]]; then
        if [[ -d $(basename $repo) ]]; then
            git_pull $repo
        else
            git_clone $repo
        fi
    fi
done
cd ..

# Download latest releases
GITHUB_RELEASES="
    breakintoprogram/agon-bbc-basic bbcbasic.bin
    breakintoprogram/agon-mos MOS.bin
    envenomator/agon-ez80asm ez80asm_agon.zip 
    envenomator/agon-flash flash.bin
    envenomator/agon-hexload hexload.bin
    envenomator/agon-hexload hexload.dll
"

mkdir -p $DOWNLOAD
cd $DOWNLOAD
echo "$GITHUB_RELEASES" | while read repo filename; do
    if [[ -n $repo && -n $filename ]]; then
        download_latest $repo $filename
    fi
done
cd ..

#root folder
echo -e "SET KEYBOARD 1\nLOAD bbcbasic.bin\nrun" > $FOLDERNAME/autoexec.txt
cp $DOWNLOAD/MOS.bin $FOLDERNAME/
crc32 $DOWNLOAD/MOS.bin > $FOLDERNAME/MOS.crc32
cp $DOWNLOAD/bbcbasic.bin $FOLDERNAME/
cp -r $REPOS/agon-forth/forth16/ $FOLDERNAME/forth16

#games
cp $REPOS/agon-sokoban/binaries/* $FOLDERNAME/games/sokoban/
cp $REPOS/Agon-rokky/bin/* $FOLDERNAME/games/

#utils
cp $REPOS/toms-agon-experiments/agon-bench/bin/agon-bench.bin $FOLDERNAME/utils/

#docs
cp $REPOS/agon-docs.wiki/*.md $FOLDERNAME/docs/

#mos
cd $FOLDERNAME/mos
cp ../../$REPOS/agon-utilities/Nano/Release/Nano.bin .
cp ../../$REPOS/agon-utilities/Comp/Release/Comp.bin .
cp ../../$REPOS/agon-utilities/More/Release/More.bin .
cp ../../$REPOS/agon-utilities/Memfill/Release/Memfill.bin .
cp ../../$REPOS/agon-projects/hexdump/Release/hexdump.bin .
cp ../../$REPOS/agon-projects/hexdumpm/Release/hexdumpm.bin .
cp ../../$REPOS/agon-projects/strings/Release/strings.bin .
unzip ../../$REPOS/ez80asm_agon.zip
cd ../..

if [[ -x $(which zip) ]]; then
    zip -r $FOLDERNAME.zip $FOLDERNAME/
fi

