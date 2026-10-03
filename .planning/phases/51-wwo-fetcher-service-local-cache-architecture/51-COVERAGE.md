# API Coverage — World Weather Online (WWO)

> Full coverage by default. Opt-outs are explicit, reasoned decisions.

| capability | decision | reason |
|---|---|---|
| local_weather_forecast | INTEGRATE | |
| current_conditions | INTEGRATE | |
| hourly_intervals_tp1 | INTEGRATE | |
| multi_day_forecast | INTEGRATE | |
| air_quality_index_aqi | INTEGRATE | |
| weather_alerts | INTEGRATE | |
| astronomy_sun_moon | INTEGRATE | |
| marine_weather | OPT-OUT | not needed for desktop status bar widget |
| historical_weather | OPT-OUT | desktop status bar only displays current conditions and future forecast |
| ski_weather | OPT-OUT | desktop environment targets general municipal weather |
| search_autocomplete_api | OPT-OUT | city resolved statically from illogical-impulse config.json |
| time_zone_api | OPT-OUT | local system time provided by system clock |
