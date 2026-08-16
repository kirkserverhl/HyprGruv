#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# weather info from wttr. https://github.com/chubin/wttr.in
# Remember to add city

# Legacy copy — live script is ~/.config/waybar/scripts/get-weather.sh
city="${WEATHER_CITY:-Raleigh,NC}"
cachedir=~/.cache/rbn
cachefile=${0##*/}-$1

if [ ! -d $cachedir ]; then
  mkdir -p $cachedir
fi

if [ ! -f $cachedir/$cachefile ]; then
  touch $cachedir/$cachefile
fi

# Save current IFS
SAVEIFS=$IFS
# Change IFS to new line.
IFS=$'\n'

cacheage=$(($(date +%s) - $(stat -c '%Y' "$cachedir/$cachefile")))
if [ $cacheage -gt 1740 ] || [ ! -s $cachedir/$cachefile ]; then
  data=($(curl -s https://en.wttr.in/"$city"$1\?0qnT 2>&1))
  echo ${data[0]} | cut -f1 -d, >$cachedir/$cachefile
  echo ${data[1]} | sed -E 's/^.{15}//' >>$cachedir/$cachefile
  echo ${data[2]} | sed -E 's/^.{15}//' >>$cachedir/$cachefile
fi

weather=($(cat $cachedir/$cachefile))

# Restore IFSClear
IFS=$SAVEIFS

#temperature=$(echo ${weather[2]} | sed -E 's/([[:digit:]])\.\./\1 to /g')
temperature=$(curl -s "https://wttr.in/${city}?format=%t" | sed 's/+//')

#echo ${weather[1]##*,}

# https://www.nerdfonts.com/cheat-sheet
case $(echo ${weather[1]##*,} | tr '[:upper:]' '[:lower:]') in
"clear" | "sunny")
  condition="" # nf-weather-day_sunny
  ;;
"partly cloudy")
  condition="" # nf-weather-day_cloudy
  ;;
"cloudy")
  condition="" # nf-weather-cloudy
  ;;
"overcast")
  condition="" # nf-weather-cloud
  ;;
"haze")
  condition="" # nf-weather-dust
  ;;
"fog" | "freezing fog")
  condition="" # nf-weather-fog
  ;;
"patchy rain possible" | "patchy light drizzle" | "light drizzle" | "patchy light rain" | "light rain" | "light rain shower" | "mist" | "rain")
  condition="" # nf-weather-showers
  ;;
"moderate rain at times" | "moderate rain" | "heavy rain at times" | "heavy rain" | "moderate or heavy rain shower" | "torrential rain shower" | "rain shower")
  condition="" # nf-weather-rain
  ;;
"patchy snow possible" | "patchy sleet possible" | "patchy freezing drizzle possible" | "freezing drizzle" | "heavy freezing drizzle" | "light freezing rain" | "moderate or heavy freezing rain" | "light sleet" | "ice pellets" | "light sleet showers" | "moderate or heavy sleet showers")
  condition="" # nf-weather-sleet
  ;;
"blowing snow" | "moderate or heavy sleet" | "patchy light snow" | "light snow" | "light snow showers")
  condition="" # nf-weather-snow
  ;;
"blizzard" | "patchy moderate snow" | "moderate snow" | "patchy heavy snow" | "heavy snow" | "moderate or heavy snow with thunder" | "moderate or heavy snow showers")
  condition="" # nf-weather-snow_wind
  ;;
"thundery outbreaks possible" | "patchy light rain with thunder" | "moderate or heavy rain with thunder" | "patchy light snow with thunder")
  condition="" # nf-weather-storm_showers
  ;;
*)
  condition="" # nf-fa-exclamation_triangle (fallback icon)
  echo -e "{\"text\":\""$condition"\", \"alt\":\""${weather[0]}"\", \"tooltip\":\""${weather[0]}: $temperature ${weather[1]}"\"}"
  ;;
esac

#echo $temp $condition

echo -e "{\"text\":\""$condition $temperature"\", \"alt\":\""${weather[0]}"\", \"tooltip\":\""${weather[0]}: $temperature ${weather[1]}"\"}"

cached_weather=" $temperature  \n$condition ${weather[1]}"

echo -e $cached_weather >~/.cache/.weather_cache
