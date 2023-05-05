#!/usr/bin/env bash
WWW_CURL="/usr/bin/curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 40 -L -k"
ONION_CURL="/usr/bin/torsocks /usr/bin/curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 40 -L -k"
OUTPUT="index.html"
HEAD="head.html"
BOTTOM="bottom.html"
WWW_ADDR_LIST="www-addresses.list"
ONION_ADDR_LIST="onion-addresses.list"


##### Define

check_www_url()
{
local SYSTEM=$1
local STATUS=$($WWW_CURL --url "$SYSTEM" -w "%{http_code}\n" -f --silent -o /dev/null)
case "$STATUS" in
  200) return 0 ;;
  403) return 0 ;;
  *)   return 1 ;;
esac
return 1
}

check_onion_url()
{
local SYSTEM=$1
local STATUS=$($ONION_CURL --url "$SYSTEM" -w "%{http_code}\n" -f --silent -o /dev/null)
case "$STATUS" in
  200) return 0 ;;
  403) return 0 ;;
  *)   return 1 ;;
esac
return 1
}

generate_www_html()
{
cat << EOF >> $OUTPUT
    <h2>Интернет Адреси:</h2>
    <div class="body">
EOF
for address in $WWW_ADDRESSES
do
cat << EOF >> $OUTPUT
       <p> <a href="$address" target="_blank">$address</a> - Проверен на $(env TZ=Europe/Sofia date '+%H:%M %x %Z') </p>
EOF
done
cat << EOF >> $OUTPUT
    </div>
EOF
}

generate_onion_html()
{
cat << EOF >> $OUTPUT
    <h2>Лучени Адреси:</h2>
    <div class="body">
EOF
for address in $ONION_ADDRESSES
do
cat << EOF >> $OUTPUT
       <p> <a href="$address" target="_blank">$address</a> - Проверен на $(env TZ=Europe/Sofia date '+%H:%M %x %Z') </p>
EOF
done
cat << EOF >> $OUTPUT
    </div>
EOF
}

##### Execute

cd $(dirname $OUTPUT)
git pull --rebase --quiet > /dev/null 2>&1

cat $HEAD > $OUTPUT

WWW_ADDRESSES=""
for www_address in $(cat $WWW_ADDR_LIST)
do
  check_www_url $www_address
  [[ $? -eq 0 ]] && WWW_ADDRESSES+="$www_address"$'\n'
done
generate_www_html

ONION_ADDRESSES=""
for onion_address in $(cat $ONION_ADDR_LIST)
do
  check_onion_url $onion_address
  [[ $? -eq 0 ]] && ONION_ADDRESSES+="$onion_address"$'\n'
done
generate_onion_html

cat $BOTTOM >> $OUTPUT

git add .
git commit -m "Update $RANDOM" --quiet
git push --dry-run --quiet && git push --quiet -u --no-progress > /dev/null 2>&1

exit $?

