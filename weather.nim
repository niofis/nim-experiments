import httpclient, json

var client = newHttpClient()
var res = client.getContent("http://api.wunderground.com/api/7fd890ff05d79ae4/conditions/q/29.082522,-110.962131.json")
var js_res = parseJson(res)
var current = js_res["current_observation"]
echo current{"display_location", "full"}.str
echo current["observation_time"].str
echo current["weather"].str
echo current["temp_c"].fnum, " C"
echo current["relative_humidity"].str, " Humidity"
