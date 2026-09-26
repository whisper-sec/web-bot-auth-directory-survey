#!/bin/sh
# Probe a population for Web Bot Auth key directories. One request per host, redirects followed,
# identified crawler, 0.4s apart, single pass, no retries.
#
# Two corrections over the first version of this script, both of which changed results:
#
#  1. -L. Without it every 3xx reads as absent, which wrongly reported meta.com, browserbase.com,
#     librechat.ai and usenotra.com as having no directory.
#  2. The key extractor accepts a BARE JWK object, not only {"keys":[...]} and a bare array. The
#     draft shows a JWK Set, but shopify.com serves a single bare JWK, and treating that as
#     unparseable wrongly filed a conformant key alongside SPA index pages.
#
# Recorded URLs have their query strings stripped: a redirect chain can carry a third party's
# session state, and that does not belong in a published dataset.
UA='WhisperWebBotAuthStudy/1.0 (+https://whisper.online/.well-known/probing.txt; one request per host; research into Web Bot Auth key directory deployment)'
P='/.well-known/http-message-signatures-directory'
OUT="${1:-data/results.tsv}"
printf 'domain\tstatus\tcontent_type\tfinal_url\tkeys\tenvelope\tverdict\n' > "$OUT"
while read -r d; do
  [ -n "$d" ] || continue
  r=$(curl -sL --max-time 15 -A "$UA" -w '\n%{http_code}\t%{content_type}\t%{url_effective}' "https://$d$P" 2>/dev/null)
  meta=$(printf '%s' "$r" | tail -1)
  code=$(printf '%s' "$meta" | cut -f1); ctype=$(printf '%s' "$meta" | cut -f2)
  fin=$(printf '%s' "$meta" | cut -f3 | sed 's/?.*$/?[query removed]/')
  body=$(printf '%s' "$r" | sed '$d')
  ke=$(printf '%s' "$body" | python3 -c "
import sys, json
try:
    j = json.load(sys.stdin)
except Exception:
    print('-1\tunparseable'); raise SystemExit
if isinstance(j, dict) and 'keys' in j:
    ks = j['keys']; env = 'jwk-set'
elif isinstance(j, list):
    ks = j; env = 'bare-array'
elif isinstance(j, dict) and j.get('kty'):
    ks = [j]; env = 'bare-jwk'          # shopify.com serves this shape
else:
    print('-1\tnot-a-directory'); raise SystemExit
print('%d\t%s' % (len(ks), env))
" 2>/dev/null || printf -- '-1\tunparseable')
  keys=$(printf '%s' "$ke" | cut -f1); env=$(printf '%s' "$ke" | cut -f2)
  case "$code" in
    200) [ "${keys:--1}" -gt 0 ] && v=LIVE || { [ "${keys:--1}" -eq 0 ] && v=EMPTY || v=NOT_A_DIRECTORY; } ;;
    404|410) v=ABSENT ;;
    000)     v=UNREACHABLE ;;
    403|401) v=REFUSED ;;
    *)       v="HTTP$code" ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$d" "$code" "${ctype:-none}" "$fin" "${keys:--1}" "$env" "$v" >> "$OUT"
  printf '  %-56s %-4s %-16s %s\n' "$d" "$code" "$v" "$env"
  sleep 0.4
done < candidates.txt
