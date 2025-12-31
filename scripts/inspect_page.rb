require 'httparty'
require 'json'
url='https://prod95-cdn.dr-massive.com/api/page?device=web_browser&ff=idp%2Cldp%2Crpt&include=sitemap%2Cnavigation%2Cgeneral%2Ci18n%2Cplayback%2Clinear%2CfeatureFlags&lang=da&segments=drtv%2Coptedin&sub=Anonymous2&path=%2Ftv-guide&text_entry_format=html'
r=HTTParty.get(url, headers: {'Accept'=>'application/json'})
j=JSON.parse(r.body)
items=j['entries'][0]['list']['items']
puts "Items: #{items.length}"
items.each_with_index do |it,i|
  tile = it['images'] && it['images']['tile']
  mid = tile && tile[/EntityId='(\d+)'/,1]
  puts "#{i}: channelShortCode=#{it['channelShortCode']} id=#{it['id']} customId=#{it['customId']} entityId=#{mid} title=#{it['title']}"
end
