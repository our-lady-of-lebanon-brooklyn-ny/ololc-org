#!/bin/bash

# pdftk Announcement\ to\ Mary.pdf Anaphora\ pack\ St.\ John\ Chrysostom.pdf cat output foo.pdf
# pdftk foo.pdf update_info <( pdftk Announcement\ to\ Mary.pdf dump_data | grep --after-context=1 'InfoKey: Title' ; pdftk foo.pdf dump_data | grep -E '^Info|Bookmark' ) output foo2.pdf

anaphoraPdf='/tmp/pdf/Announcement to Mary.pdf'
wordPdf='/tmp/pdf/Anaphora pack St. John Chrysostom.pdf'

catPdf="$(mktemp)"
catOptions='A1-end W1-end'

set -x
set -o errexit

rc='0'
(
  pdftk A="${anaphoraPdf}" W="${wordPdf}" cat ${catOptions} output "${catPdf}"
  pdftk "${catPdf}" update_info \
    <(
      pdftk "${anaphoraPdf}" dump_data | grep --after-context=1 'InfoKey: Title'
      pdftk "${catPdf}" dump_data | grep -E '^Info|Bookmark'
    ) \
    output -
) || rc="$?"

rm "${catPdf}"
exit "${rc}"
