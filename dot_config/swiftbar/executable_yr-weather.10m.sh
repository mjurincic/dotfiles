#!/bin/bash
# <swiftbar.title>yr.no weather</swiftbar.title>
# <swiftbar.desc>Local forecast from MET Norway (yr.no) with a "what to wear" hint.</swiftbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
#
# Location: uses your Mac's location via CoreLocationCLI when it's allowed,
# otherwise falls back to the place below.
FALLBACK_NAME="Trondheim"
FALLBACK_LAT="63.4305"
FALLBACK_LON="10.3951"
HOURS=12

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
UA="dotfiles-swiftbar/1.0 github.com/mjurincic/dotfiles"   # MET Norway requires an identifying User-Agent
CACHE="$HOME/Library/Caches/yr-weather"
mkdir -p "$CACHE"

# ---------- Location (cached 1 hour) ----------
NAME="$FALLBACK_NAME"; LAT="$FALLBACK_LAT"; LON="$FALLBACK_LON"; SOURCE="fallback"
LOC="$CACHE/location"
SELF="${SWIFTBAR_PLUGIN_PATH:-$0}"
# "Refresh" in the menu calls the script with --relocate first: forget the cached location
if [ "$1" = "--relocate" ]; then rm -f "$LOC"; exit 0; fi
if [ -f "$LOC" ] && [ $(( $(date +%s) - $(stat -f %m "$LOC") )) -lt 3600 ]; then
  read -r LAT LON SOURCE NAME < "$LOC"
elif command -v CoreLocationCLI >/dev/null; then
  # Times out quickly if Location Services are off or permission was not granted
  out=$( (CoreLocationCLI --format "%latitude %longitude %locality" 2>/dev/null & pid=$!; sleep 5; kill $pid 2>/dev/null) | head -1 )
  set -- $out
  if [[ "$1" =~ ^-?[0-9]+\.[0-9]+$ && "$2" =~ ^-?[0-9]+\.[0-9]+$ ]]; then
    LAT="$1"; LON="$2"; shift 2; NAME="${*:-Current location}"; SOURCE="auto"
  fi
  echo "$LAT $LON $SOURCE $NAME" > "$LOC"
fi
LAT=$(printf "%.4f" "$LAT"); LON=$(printf "%.4f" "$LON")   # MET asks for max 4 decimals

# ---------- Forecast (MET caches upstream; we keep the last good copy) ----------
DATA="$CACHE/forecast.json"
TMP="$DATA.tmp"
if curl -fsS --max-time 15 -A "$UA" \
     "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=$LAT&lon=$LON" -o "$TMP"; then
  mv "$TMP" "$DATA"
fi
# ---------- Next 90 minutes: MET Norway radar nowcast (same as yr.no's "Precipitation forecast") ----------
# Only available in the Nordic area; if radar is down or we're outside coverage, the line is skipped.
NC="$CACHE/nowcast.json"
if curl -fsS --max-time 10 -A "$UA" \
     "https://api.met.no/weatherapi/nowcast/2.0/complete?lat=$LAT&lon=$LON" -o "$NC.tmp"; then
  mv "$NC.tmp" "$NC"
else
  rm -f "$NC.tmp" "$NC"
fi
NOWCAST=""
if [ -s "$NC" ]; then
  NOWCAST=$(jq -r '
    def wet: . >= 0.1;                                   # mm/h
    def hm: strflocaltime("%H:%M");
    def bar: if . < 0.1 then "·" elif . < 0.5 then "▂" elif . < 1 then "▃"
             elif . < 2.5 then "▅" elif . < 5 then "▆" else "█" end;
    (.properties.meta.radar_coverage // "ok") as $cov
    | [ .properties.timeseries[]
        | {t: (.time | fromdateiso8601), p: (.data.instant.details.precipitation_rate // 0)}
        | select(.t >= now - 300 and .t <= now + 5400) ] as $s   # next 90 min, like yr.no
    | if $cov != "ok" or ($s | length) == 0 then empty
      else
        ($s | last | .t | hm) as $end
        | ($s | map(select(.p | wet))) as $wetsteps
        | if ($wetsteps | length) == 0 then
            "☂️ No precipitation the next 90 minutes (until \($end))"
          else
            (if ($s[0].p | wet) then
               ([ $s[] | select(.p | wet | not) ] | first) as $dry
               | if $dry then "☔ Precipitation now, stopping around \($dry.t | hm)"
                 else "☔ Precipitation the next 90 minutes (until \($end))" end
             else
               "☔ Precipitation from about \($wetsteps[0].t | hm)"
             end),
            "   \($s[0].t | hm) \($s | map(.p | bar) | join("")) \($end) | font=Menlo size=12"
          end
      end
  ' "$NC" 2>/dev/null)
fi

if [ ! -s "$DATA" ]; then
  echo "☁️ –"; echo "---"; echo "Couldn't reach yr.no | color=red"; echo "Refresh | refresh=true"; exit 0
fi

jq -r --arg name "$NAME" --arg src "$SOURCE" --argjson hours "$HOURS" \
      --arg self "$SELF" --arg nowcast "$NOWCAST" --arg url "https://www.yr.no/en/forecast/daily-table/$LAT,$LON" '
  def icon($s):
    ($s // "") as $s
    | ($s | test("night")) as $n
    | if   $s|test("thunder")            then "⛈"
      elif $s|test("snow")               then "🌨"
      elif $s|test("sleet")              then "🌨"
      elif $s|test("rainshowers")        then "🌦"
      elif $s|test("rain")               then "🌧"
      elif $s|test("fog")                then "🌫"
      elif $s|test("partlycloudy|fair")  then (if $n then "☁️" else "⛅" end)
      elif $s|test("clearsky")           then (if $n then "🌙" else "☀️" end)
      elif $s|test("cloudy")             then "☁️"
      else "🌡" end;
  def describe($s):
    ($s // "unknown") | sub("_(day|night|polartwilight)$"; "")
    | gsub("andthunder"; " and thunder") | sub("^light"; "light ") | sub("^heavy"; "heavy ")
    | sub("partlycloudy"; "partly cloudy") | sub("clearsky"; "clear sky")
    | sub("showers"; " showers") | sub("^(?<f>.)"; "\(.f | ascii_upcase)");
  def r: (. * 10 | round) / 10;
  def deg: round | if . == 0 then 0 else . end;   # avoid "-0"
  def dir($d): ["↓","↙","←","↖","↑","↗","→","↘"][((($d + 22.5) / 45) | floor) % 8];   # arrow = where the wind blows to
  # Wind chill (°C, wind in m/s), only meaningful when cold and windy
  def feels($t; $v): ($v * 3.6) as $k
    | if $t <= 10 and $k > 4.8
      then (13.12 + 0.6215*$t - 11.37*pow($k;0.16) + 0.3965*$t*pow($k;0.16)) | deg
      else $t | deg end;
  def hour: .time | fromdateiso8601 | strflocaltime("%H");

  .properties.timeseries as $ts
  | ($ts | map(select((.time|fromdateiso8601) >= (now - 3600))) ) as $ts
  | $ts[0] as $now
  | $now.data.instant.details as $d
  | ($now.data.next_1_hours.summary.symbol_code // $now.data.next_6_hours.summary.symbol_code) as $sym
  | ($ts[0:$hours]) as $next
  | ($next | map(.data.instant.details.air_temperature)) as $temps
  | ($next | map(feels(.data.instant.details.air_temperature; .data.instant.details.wind_speed))) as $feels
  | ($next | map(.data.next_1_hours.details.precipitation_amount // 0) | add | r) as $rain
  | ($next | map(.data.instant.details.wind_speed) | max) as $wind
  | ($next | map(.data.next_1_hours.summary.symbol_code // "") | join(" ")) as $syms
  | ($next | map(select((.data.next_1_hours.details.precipitation_amount // 0) >= 0.2)) | first | if . then hour else null end) as $rainFrom
  | ($feels | min) as $coldest
  | ( [ if   $coldest <= -10 then "Winter jacket, hat, gloves and scarf"
        elif $coldest <= 0   then "Warm jacket, hat and gloves"
        elif $coldest <= 8   then "Jacket and a warm layer"
        elif $coldest <= 15  then "Light jacket or sweater"
        else "T-shirt weather" end ]
      + (if $syms|test("snow|sleet") then ["winter boots"] elif $rain >= 0.5 then ["rain jacket or umbrella"] else [] end)
      + (if $wind >= 10 then ["something windproof"] else [] end)
    | join(", ") ) as $wear

  | "\(icon($sym)) \($d.air_temperature|deg)°",
    "---",
    "\($name)\(if $src == "fallback" then "" else " 📍" end): \(describe($sym)), \($d.air_temperature|r)° | size=14",
    "Feels like \(feels($d.air_temperature; $d.wind_speed))° · Wind \($d.wind_speed|r) m/s \(dir($d.wind_from_direction)) · Humidity \($d.relative_humidity|round)%",
    "---",
    "👕 \($wear)",
    "Next \($hours)h: \($temps|min|deg)° to \($temps|max|deg)°, " +
      (if $rain >= 0.1 then "\($rain) mm precipitation from \($rainFrom // "later"):00" else "dry" end),
    ( if $nowcast != "" then ($nowcast | split("\n")[]) else empty end ),
    "---",
    ( $next[] | (.data.next_1_hours.details.precipitation_amount // 0) as $p
      | "\(hour)  \(icon(.data.next_1_hours.summary.symbol_code))  \(.data.instant.details.air_temperature|deg|tostring|.[0:4]|("   " + .)[-3:])°"
        + (if $p > 0 then "  \($p) mm" else "" end)
        + " | font=Menlo size=12" ),
    "---",
    "Open full forecast on yr.no | href=\($url)",
    "Refresh (and update location) | bash=\($self) param1=--relocate terminal=false refresh=true",
    "Weather data: MET Norway (CC BY 4.0) | size=10 color=gray"
' "$DATA" 2>/dev/null || { echo "☁️ ?"; echo "---"; echo "Couldn't read forecast | color=red"; echo "Refresh | refresh=true"; }
