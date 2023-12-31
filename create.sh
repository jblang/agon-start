#!/bin/bash
set -euo pipefail  # https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425

DATE=`date +%m-%d-%Y`
DOWNLOAD=download
REPOS=repos
SDDIR=SD_card
MOSDIR=$SDDIR/mos

HARDWARE_REPOS="
TheByteAttic/AgonLight
TheByteAttic/AgonORIGINS
OLIMEX/AgonLight2    
"

FIRMWARE_REPOS="
breakintoprogram/agon-vdp
breakintoprogram/agon-mos
"

FIRMWARE_RELEASES="
breakintoprogram/agon-mos MOS.bin
"

ALT_FIRMWARE_REPOS="
AgonConsole8/agon-vdp
S0urceror/AgonElectron
S0urceror/AgonElectronHAL
"

BBCBASIC_REPOS="
breakintoprogram/agon-bbc-basic
breakintoprogram/agon-bbc-basic-adl
"

DOC_REPOS="
breakintoprogram/agon-docs.wiki
oldpatientsea/agon-bbc-basic-manual
"

UTIL_RELEASES="
envenomator/agon-ez80asm ez80asm_agon.zip 
envenomator/agon-flash flash.bin
envenomator/agon-hexload hexload.bin
envenomator/agon-hexload hexload.dll
"

UTIL_REPOS="
avalonbits/aed
eightbitswide/agon_64cfontloader
envenomator/agon-ez80asm
envenomator/agon-flash
envenomator/agon-hexload
lennart-benschop/agon-utilities
nihirash/Agon-MOS-Tools
nihirash/Agon-CPM2.2
robogeek42/agon_sped
sijnstra/agon-projects
tomm/toms-agon-experiments
"

FORTH_REPOS="
lennart-benschop/agon-forth
"

GAME_REPOS="
8BitVino/draegerman
eightbitswide/AgonLight-Game-Library
envenomator/agon-sokoban
james7780/Agon_SpaceBirds
lovejoy777/Haunted_House
LuzrBum/Agon-Games 
LuzrBum/Agon-OregonTrail
NicholasPratt/Nova-Star
NicholasPratt/Pizza-Dash
NicholasPratt/Realm
nihirash/Agon-rokky
oldpatientsea/agon-snakedemake 
oldpatientsea/DRUG-WARS-for-the-Agon-Light
pgregory/agon-light-invaders
theflynn49/fsudoku
tonedef71/agon-death-house
tonedef71/agon-jotto-2020
tonedef71/agon-nomis
tonedef71/agon-snac-snake
tonedef71/agon-tinacot
TurBoss/agon-snakes
TurBoss/agon-tetris
xianpinder/Agon
"

DEMO_REPOS="
craiglp/agon-life
james7780/Agon_C_Mandelbrot
movievertigo/movievertigo.github.io
TurBoss/agon-badapple
"

EXAMPLE_REPOS="
envenomator/Agon
james7780/Agon_C_Sprites 
learnagon/vdp_study
LuzrBum/Agon-Projects
mikedailly/Agon
oldpatientsea/agon-notes-and-examples
OLIMEX/AgonLight-WPC
pngwen/agon-bas
sandergroen/Agon-Basic-Projects
schur/Agon-Light-Assembly
TechCowboy/Agon-FUN
TurboVega/agon512k
"

CROSSDEV_REPOS="
astralaster/agon-light-emulator
envenomator/agon-vdpflash
nihirash/Agon-MOS-SDCC-Template
nihirash/agon-music-track-compiler 
pcawte/AgDev
tomm/agon-cpu-emulator 
tomm/ez80
"

BBCBASIC_RELEASES="
breakintoprogram/agon-bbc-basic bbcbasic.bin
breakintoprogram/agon-bbc-basic-adl bbcbasic24.bin
"

latest_url() {
    curl -s "https://api.github.com/repos/$1/releases/latest" \
    | grep "browser_download_url.*$2" \
    | cut -d : -f 2,3 \
    | tr -d \"
}

github_download() {
    if [[ ! -f $2 ]]; then
        echo "Downloading $2 from latest release of $1..."
        curl -sLO $(latest_url "$1" "$2")
    else
        echo "Skipping existing file $2 of $1; delete to redownload..."
    fi
}

clone_or_pull() {
    if [[ -d $(basename $1) ]]; then
        echo "Pulling $1..."
        cd $(basename $1)
        git pull -q
        cd ..
    else
        echo "Cloning $1..."
        git clone -q "https://github.com/$1.git"
    fi
}

crc32() {
    cat "$1" | gzip -1 -c | tail -c8 | xxd -p
}

github_refresh() {
    mkdir -p $REPOS
    cd $REPOS
    echo "$1" | while read repo; do
        if [[ -n $repo && $repo != '#'* ]]; then
            clone_or_pull $repo
        fi
    done
    cd ..
}

github_download() {
    mkdir -p $DOWNLOAD
    cd $DOWNLOAD
    echo "$1" | while read repo filename; do
        if [[ -n $repo && -n $filename  && $repo != "#*" ]]; then
            github_download $repo $filename
        fi
    done
    cd ..
}

install_hardware() {
    github_refresh "$HARDWARE_REPOS"
}

install_firmware() {
    github_refresh "$FIRMWARE_REPOS"
    github_download "$FIRMWARE_RELEASES"
    mkdir -p $MOSDIR
    cp $DOWNLOAD/MOS.bin $SDDIR/
    crc32 $DOWNLOAD/MOS.bin > $SDDIR/MOS.crc32
}

install_bbcbasic() {
    github_refresh "$BBCBASIC_REPOS"
    github_download "$BBCBASIC_RELEASES"
    BBCDIR=$SDDIR/bbcbasic
    echo -e "SET KEYBOARD 1\nLOAD bbcbasic.bin\nrun" > $SDDIR/autoexec.txt
    cp $DOWNLOAD/bbcbasic.bin $SDDIR
    cp $DOWNLOAD/bbcbasic24.bin $SDDIR
    mkdir -p $BBCDIR
    cp -r $REPOS/agon-bbc-basic/{examples,tests,resources,COPYING,README.md} $BBCDIR
}

install_docs() {
    github_refresh "$DOC_REPOS"
    DOCSDIR=$SDDIR/docs
    mkdir -p $DOCSDIR
    mkdir -p $DOCSDIR/bbcbasic
    cp $REPOS/agon-docs.wiki/*.md $DOCSDIR
    cp $REPOS/agon-bbc-basic-manual/modules/ROOT/pages/*.adoc $DOCSDIR/bbcbasic
}

install_utils() {
    github_refresh "$UTIL_REPOS"
    github_download "$UTIL_RELEASES"
    mkdir -p $MOSDIR
    mkdir -p $SDDIR/utils
    cp $REPOS/agon-utilities/Comp/Release/Comp.bin $MOSDIR
    cp $REPOS/agon-utilities/Font/Release/Font.bin $MOSDIR
    cp $REPOS/agon-utilities/Memfill/Release/Memfill.bin $MOSDIR
    cp $REPOS/agon-utilities/More/Release/More.bin $MOSDIR
    cp $REPOS/agon-utilities/Nano/Release/Nano.bin $MOSDIR
    cp -r $REPOS/agon-utilities/Font/fonts $SDDIR
    cp $REPOS/agon-projects/hexdump/Release/hexdump.bin $MOSDIR
    cp $REPOS/agon-projects/hexdumpm/Release/hexdumpm.bin $MOSDIR
    cp $REPOS/agon-projects/memsave/Release/memsave.bin $MOSDIR
    cp $REPOS/agon-projects/strings/Release/strings.bin $MOSDIR
    cp $REPOS/toms-agon-experiments/vi/bin/vi.bin $MOSDIR
    cp $REPOS/toms-agon-experiments/agon-bench/bin/agon-bench.bin $SDDIR/utils/
    unzip $DOWNLOAD/ez80asm_agon.zip -d $MOSDIR
    cp $DOWNLOAD/flash.bin $MOSDIR
}


install_forth() {
    github_refresh "$FORTH_REPOS"
    FORTHDIR=$SDDIR/forth
    mkdir $FORTHDIR
    cp -r $REPOS/agon-forth/{examples,examples_agon,forth16,forth24,forthlib,LICENSE,README.md} $FORTHDIR
}

install_games() {
    github_refresh "$GAME_REPOS"
    GAMESDIR=$SDDIR/games
    mkdir -p $GAMESDIR
    mkdir -p $GAMESDIR/sokoban
    cp $REPOS/agon-sokoban/binaries/* $GAMESDIR/sokoban/
    cp $REPOS/Agon-rokky/bin/1.04+/* $GAMESDIR
}

install_demos() {
    github_refresh "$DEMO_REPOS"
    MVDIR=$REPOS/movievertigo.github.io/downloads/agonlight/
    DEMOSDIR=$SDDIR/demos
    mkdir -p $DEMOSDIR
    unzip $MVDIR/badapple/agonlightbadapple.zip -d $DEMOSDIR
    cp $MVDIR/mandelbrot/mandelbrot.bin $DEMOSDIR
}

install_alt_firmware() {
    github_refresh "$ALT_FIRMWARE_REPOS"
}

install_examples() {
    github_refresh "$EXAMPLE_REPOS"
}

install_crossdev() {
    github_refresh "$CROSSDEV_REPOS"
}

cleanup() {
    rm -rf $SDDIR
    mkdir $SDDIR
}

create_archive() {
    if [[ -x $(which zip 2> /dev/null) ]]; then
        zip -r $SDDIR.zip $SDDIR/
    elif [[ -x $(which tar 2> /dev/null) && -x $(which gzip 2>/dev/null) ]]; then
        tar cfz $SDDIR.tar.gz $SDDIR/
    else
        echo "No archive software installed; skipping archive creation."
    fi
}


cleanup
install_hardware
install_firmware
install_bbcbasic
install_utils
install_docs
install_forth
install_games
install_demos
install_alt_firmware
install_examples
install_crossdev
create_archive