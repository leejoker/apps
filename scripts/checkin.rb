#get请求 返回响应体
require 'uri'
require 'net/http'
require 'json'

uri = URI.parse("http://127.0.0.1:8083/hacpai/checkin")
http = Net::HTTP.new(uri.host, uri.port)
req = Net::HTTP::Get.new(uri.path)
res = http.request(req)
json = JSON.parse(res.body)
json = JSON.parse(json)

# 保存签到日志
File.open("/home/ubuntu/hacpai_chein.log", "a+") do |file|
  if (file.readlines.length != 0)
    file.puts "########################################"
  end
  file.puts "#{Time.new} 签到"
  json.each do |k, v|
    file.puts "#{k} : #{v}"
  end
end
