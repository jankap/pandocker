#!/usr/bin/env bats

##
## Testing the full variant
##

log() {
  local -r log="$BATS_TEST_DIRNAME/${BATS_TEST_FILENAME##*/}.log"
  echo "$@" >> "$log"
}

initial_setup(){
  #log "initial setup"
  # remove artefacts from previous tests,
  # but keep the directory structure
  find $OUT -type f -and -not -name .keep -delete
  # allow all users to write artefacts
  chmod a+rwx $OUT
  # mount a dedicated volume and put the tests files in it
  docker create --name pandoc-volumes dalibo/pandocker:$TAG
  docker cp tests pandoc-volumes:/pandoc/
}

setup() {
  # use `TAG=stable bats docker.bats` to test the stable version
  export TAG=${TAG:-latest}
  export VARIANT=${VARIANT:-}
  log "setup: TAG = $TAG & VARIANT=$VARIANT"
  export DOCKER_OPT="--rm --volumes-from pandoc-volumes "
  export PANDOC="docker run $DOCKER_OPT dalibo/pandocker:$TAG --verbose"
  export DIFF="docker run $DOCKER_OPT --entrypoint=diff dalibo/pandocker:$TAG"
  export IN=tests/input
  export EXP=tests/expected
  export OUT=tests/output
  if [ "${BATS_TEST_NUMBER}" = 1 ];then
    initial_setup
  fi
}

final_teardown() {
  # fetch artefacts
  docker cp pandoc-volumes:/pandoc/$OUT tests
  # destroy the volume
  docker rm --force --volumes pandoc-volumes
}

teardown() {
  if [ "${#BATS_TEST_NAMES[@]}" -eq "$BATS_TEST_NUMBER" ]; then
    final_teardown
  fi
}


##
## 14xx: Fonts, Langages and Special Characters
##

## 141x: Languages

@test "1411: Generate a PDF file containing Persian characters" {
  DIR=persian
  $PANDOC --pdf-engine=xelatex \
          --template eisvogel \
          --variable mainfont='Nazli' \
          $IN/$DIR/markdown_fa.md \
          -o $OUT/$DIR/markdown_fa.pdf
}

@test "1412: Generate a PDF file containing Hindi characters" {
  DIR=persian
  $PANDOC --pdf-engine=xelatex \
          --template eisvogel \
          --variable mainfont='Lohit Devanagari' \
          $IN/$DIR/markdown_fa.md \
          -o $OUT/$DIR/markdown_fa.pdf
}

## 142x : Fonts

@test "1421: Generate a PDF file with the Noto font" {
  DIR=fonts
  $PANDOC --pdf-engine=xelatex $IN/$DIR/fonts.md \
          -o $OUT/$DIR/fonts_noto.pdf \
          --variable mainfont="Noto Sans"
}


##
## 19xx: Other entrypoints
##

@test "1911: Generate a SVG image with dia" {
    DIR=dia
    DIA="docker run $DOCKER_OPT --entrypoint dia dalibo/pandocker:$TAG --verbose"
    $DIA $IN/$DIR/db.dia --export $OUT/$DIR/db.svg
}


