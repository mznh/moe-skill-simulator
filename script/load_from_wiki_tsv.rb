#!/bin/env ruby



require 'csv'
require 'json'


data = CSV.read(ARGV[0],col_sep:"\t",headers:true)

data = data.map do |row|
  res = {}

  res["name"]  = row["name"].gsub(/,\(.+\)/,"")
  res["required"] = {}

  skills = row["skill"].split(/,/).map do |str|
    rs = /([^0-9]+)([0-9]+)/.match(str)
    if rs.nil? then
      {}
    else
      { "name" => rs[1], "value"=> rs[2].to_i }
    end
  end
  res["required"]["skill"] = skills
  res["required"]["cost"] = row["cost"]  
  res["info"] = row["説明"]
  res
end

puts "["
puts data.map!(&:to_json).join(",\n")
puts "]"


