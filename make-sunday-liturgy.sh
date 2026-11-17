#!/bin/bash

#{
#  "season": "Season 1 The Glorious Birth of Our Lord",
#  "word-file": "Annunciation to Mary.pdf",
#  "anaphora-file": "Anaphora pack St. James.pdf"
#}

# Instruct bash to be strict about error checking.
set -o errexit  # stop if an error happens
set -o nounset  # stop if an undefined variable is referenced
set -o pipefail # stop if any command within a pipe fails
set -o posix    # extra error checking

# We will log to stderr.  Get a copy of the stderr file descriptor.
# This will let us write logs even when we redirect stdout within the script
# for other purposes.
if [ -z "${fdLog:-}" ]; then
  exec {fdLog}>&2
fi
declare -r -x fdLog

rclone_source="${RCLONE_CONNECTION:-b2}:ololc-bucket/website/liturgy"
tempDir="$(mktemp -d)"
rc='0'
(
  eval "set -- $(jq --raw-output '[.season, .["word-file"], (.["reading-file"] // ""), .["anaphora-file"]] | @sh' )"
  season="$1"
  word="$2"
  reading="$3"
  anaphora="$4"

  tempWord="${tempDir}/word.pdf"
  tempReading="${tempDir}/reading.pdf"
  tempAnaphora="${tempDir}/anaphora.pdf"
  tempCat="${tempDir}/cat.pdf"

  echo "$(date): Retrieving ${word}" >&"${fdLog}"
  rclone --error-on-no-transfer copyto "${rclone_source}/${season}/${word}" "${tempWord}" || rc="$?"
  [[ "${rc}" != 0 ]] && exit "${rc}"

  readingInsert=''
  readingHandle="R=${tempDir}/word.pdf"
  if [ -n "${reading}" ]; then
    echo "$(date): Retrieving ${reading}" >&"${fdLog}"
    rclone --error-on-no-transfer copyto "${rclone_source}/${season}/${reading}" "${tempReading}" || rc="$?"
    [[ "${rc}" != 0 ]] && exit "${rc}"

    readingHandle="R=${tempReading}"
  fi

  echo "$(date): Retrieving ${anaphora}" >&"${fdLog}"
  rclone --error-on-no-transfer copyto "${rclone_source}/Anaphora/${anaphora}" "${tempAnaphora}" || rc="$?"
  [[ "${rc}" != 0 ]] && exit "${rc}"

  catOptions=(
    $(
        if [ -n "${readingInsert}" ]; then
          echo "W1-$(( readingInsert ))"
	  echo "R"
	  echo "W$(( readingInsert +1 ))-end"
        else
	  echo 'W'
	fi
    )
    'A'
  )

  echo "$(date): Combining files" >&"${fdLog}"
  pdftk "W=${tempWord}" "${readingHandle}" "A=${tempAnaphora}" cat "${catOptions[@]}" output "${tempCat}" || rc="$?"
  [[ "${rc}" != 0 ]] && exit "${rc}"

  pdftk "${tempCat}" update_info \
    <(
      pdftk "${tempWord}" dump_data | grep --after-context=1 'InfoKey: Title'
      pdftk "${tempCat}" dump_data | grep -E '^Info|Bookmark'
    ) \
    output -
) || rc="$?"

rm -r "${tempDir}"
exit "${rc}"
