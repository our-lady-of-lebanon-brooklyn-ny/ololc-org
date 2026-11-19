#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o posix

pdf="$1"
title="$2"

pdfName="$(sed -e 's/.pdf//' <<<"${pdf}" )"
dashDate="$(sed -e 's/\(..\)\(..\)\(..\)-bulletin/20\1-\2-\3/' <<<"${pdfName}" )"

mkdir -p "${pdfName}"
(
  cd "${pdfName}"
  if [ ! -e 'featured-01.png' ] ; then
    pdftoppm -png -l 1 "../${pdf}" featured
  fi
  if [ -e 'index.md' ]; then
    titleLine="$( grep '^title:' 'index.md' )"
  else
    titleLine="title: ${title}"
  fi

  (
    echo '---'
    if [ -n "${titleLine}" ] ; then
      echo "${titleLine}"
    fi
    echo "date: ${dashDate}"
    echo "publishDate: $( date --date "${dashDate} - 1 week" --iso-8601 date )"
    echo "expiryDate: $( date --date "${dashDate} + 16 weeks" --iso-8601 date )"
    echo 'url: /:sections/:contentbasename.pdf'
    echo 'draft: false'
    echo '---'
  ) >index.md

)

rclone move "${pdf}" "${RCLONE_CONNECTION_STRING:-b2}:ololc-bucket/bulletins"
