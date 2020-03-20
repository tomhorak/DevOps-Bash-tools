#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-18 13:57:12 +0100 (Fri, 18 Oct 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

section "AWS Git credentials scan"

start_time="$(start_timer)"

location="${1:-.}"

if [ "$location" = . ]; then
    :
elif [ -d "$location" ]; then
    cd "$location"
else
    cd "$(dirname "$location")"
fi

# $(pwd) more reliable than $PWD
echo "checking $(pwd)"
echo

matches="$(git grep -Ei \
    -e 'AWS_ACCESS_KEY.*=.*[[:alnum:]]+' \
    -e 'AWS_SECRET_KEY.*=.*[[:alnum:]]+' \
    -e 'AWS_SECRET_ACCESS_KEY.*=.*[[:alnum:]]+' \
    -e 'AWS_SESSION_TOKEN.*=.*[[:alnum:]]+' \
    || :
)"
if [ -f .gitallowed ]; then
    matches="$(grep -Ev -f .gitallowed <<< "$matches" || :)"
fi
matches="$(grep -Ev -e "^${0##*/}:[[:space:]]+-e[[:space:]]+'AWS_" -e '^.bash.d/aws.sh:' <<< "$matches" || :)"
if [ -n "$matches" ]; then
        # dangerous, fails silently and suppressed legitimate matches
        #grep -v -f "$gitallowed" |
        #grep -v -e '\.bash\.d/aws.sh:' \
        #        -e "${0##*/}:" |
    # shellcheck disable=SC2001
    sed 's/\(=.....\).*/\1....../' <<< "$matches"
    echo
    echo "DANGER: potential AWS credentials found in Git!!"
    exit 1
fi

time_taken "$start_time"
section2 "OK: no AWS credentials found in Git"
echo
