#!/usr/bin/env ruby

require 'csv'
require 'json'

require "./modules/ponz_encode"

class SpecialSkillSearcher

  def initialize()
    @race_list  = File.readlines("resource/race.csv").map(&:chomp)
    @skill_list = File.readlines("resource/skill.csv").map(&:chomp)
    File.open("resource/from_ava/ship__composite.json") do |file|
      @composite  = JSON.load(file)
    end
    File.open("resource/from_ava/spell__composite.json") do |file|
      @spells  = JSON.load(file)
    end
    File.open("resource/from_ava/special__composite.json") do |file|
      @specials  = JSON.load(file)
    end

  end

  def fetch_1st(str)
    res = /(\d+[a-zA-Z]+)(.*)/.match(str)
    if res.nil? then
      return nil
    end
    return res[1], res[2]
  end

  def encode_url(str)
    res = /([^?]+)\?([^&]+)&(.+)/.match(str)
    domain, race, skill = res[1], res[2].to_i, res[3]
    # race
    race_name = @race_list[race]
    # skill
    skill_set = {}
    loop do
      if res = fetch_1st(skill) then
        skill_str, other_str = res
        name, value = decode_skill(skill_str)
        skill_set[name] = value
        skill = other_str
      else
        break
      end
    end
    return race_name, skill_set
  end
  def search_ship_composite(skill_set)
    ships = []
    @composite.each do |ship|
      is_fit = ship["skill"].all? do |required_skill|
        if skill_set.has_key? required_skill and skill_set[required_skill] >= 40 then true else false end 
      end
      if is_fit then
        ships << ship["name"]
      end
    end
    ships
  end

  def list_up_multi_technic(skill_set,ship_set)
    practicable_technics = []
    [@spells, @specials].each do |technic_list|
      practicable_technics += technic_list.select do |spell|
        is_skill_sufficiency = spell["required"]["skill"].all? do |required_skill|
          name  = required_skill["name"]
          value = required_skill["value"]
          if skill_set.has_key? name and skill_set[name] >= value then true else false end
        end
        if not spell["required"].has_key? "mastery" then 
          is_skill_sufficiency
        else
          is_mastery_sufficiency = spell["required"]["mastery"].all? do |required_mastery|
            if ship_set.include?(required_mastery) then true else false end
          end
          is_skill_sufficiency and is_mastery_sufficiency
        end
      end
    end
    practicable_technics.map do |spell|
      spell["name"]
    end
  end

  def print(skill_set, ship_set,technic_set)
    puts "==============================="
    puts "スキル構成"
    skill_set.each do |k,v|
      puts "#{k.ljust(7)}\t:#{v.to_s.rjust(7)}"
    end
    puts "==============================="
    puts "複合シップ"
    ship_set.each do |ship_name|
      puts "・#{ship_name}"
    end
    puts "==============================="
    puts "複合テク"
    technic_set.each do |name|
      puts "・#{name}"
    end
  end

end

#url = "https://www.ponz-web.com/skill/?1&2ak5ua6ew7Fi25Eu26Eu27Eu28Eu29Ce30Eu31Ce"
#
searcher = SpecialSkillSearcher.new()
race,skills = searcher.encode_url(ARGV[0])
ships = searcher.search_ship_composite(skills)
technics = searcher.list_up_multi_technic(skills,ships)
searcher.print(skills,ships,technics)








