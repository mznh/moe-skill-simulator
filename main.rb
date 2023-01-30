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
    File.open("resource/spell.json") do |file|
      name_list = @spells.map{|spell| spell["name"]}
      @spells  += JSON.load(file).select do |spell|
        not name_list.include?(spell["name"])
      end
    end
    File.open("resource/from_ava/special__composite.json") do |file|
      @specials  = JSON.load(file)
    end
    File.open("resource//special.json") do |file|
      name_list = @specials.map{|spell| spell["name"]}
      @specials  += JSON.load(file).select do |spell|
        not name_list.include?(spell["name"])
      end
    end
    @player_character = {}
  end

  def fetch_1st(str)
    res = /(\d+[a-zA-Z]+)(.*)/.match(str)
    if res.nil? then
      return nil
    end
    return res[1], res[2]
  end

  def load_character(url)
    self.encode_url(url)
    self.search_ship_composite()
    self.list_up_multi_technic()
    self.calc_probabiilty_of_success()
    return @player_character
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
    @player_character["race"] = race_name
    @player_character["skills"] = skill_set
    return race_name, skill_set
  end

  def search_ship_composite()
    skill_set = @player_character["skills"]
    ships = []
    @composite.each do |ship|
      is_fit = ship["skill"].all? do |required_skill|
        if skill_set.has_key? required_skill and skill_set[required_skill] >= 40 then true else false end 
      end
      if is_fit then
        ships << ship["name"]
      end
    end
    @player_character["ships"] = ships
    return ships
  end

  #TODO 要対応
  # 要求スキルが設定されているが、実際は不要なもの（鏡花水月など）
  # マスタリーが必要だが、他で代用が聞くもの（ドルイド、ウォーリアーなど）
  def list_up_multi_technic()
    skill_set = @player_character["skills"]
    ship_set  = @player_character["ships"] 
    practicable_technics = []
    [@spells, @specials].each do |technic_list|
      practicable_technics += technic_list.select do |spell|
        is_skill_sufficiency = spell["required"]["skill"].all? do |required_skill|
          name  = required_skill["name"]
          value = required_skill["value"]
          # ここでは要求スキル以上かどうかのみ見る
          # 複合テク候補は要求スキル未満のものはリストアップされない
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
    @player_character["technics"] = practicable_technics
    practicable_technics
  end

  def calc_probabiilty_of_success()
    skills = @player_character["skills"]
    @player_character["technics"].map! do |technic|
      # 計算式は moewiki より引用
      probability = 80
      n = technic["required"]["skill"].length
      technic["required"]["skill"].each do|n_v|
        name  = n_v["name"]
        value = n_v["value"]
        if skills[name] <= value then
          probability += (value-skills[name]).rationalize*-10.0/n
        else 
          probability +=[skills[name]-value,8.0].min.rationalize*2.5/n
        end
      end
      technic["probability"] = [ probability, 1.0.rationalize/n].max.to_f
      technic
    end
  end


  def print()
    skill_set   = @player_character["skills"]
    ship_set    = @player_character["ships"] 
    technic_set = @player_character["technics"]
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
    #technic_set.sort_by! do |elm| 
    #  elm["name"]
    #end
    technic_set.each do |technic|
      if technic["probability"] >= 100.0 then
        puts "・#{technic["name"]}"
      else
        puts "・#{technic["name"]} : #{technic["probability"]}%"
      end
    end
  end
end

#url = "https://www.ponz-web.com/skill/?1&2ak5ua6ew7Fi25Eu26Eu27Eu28Eu29Ce30Eu31Ce"
#
searcher = SpecialSkillSearcher.new()
searcher.load_character(ARGV[0])
searcher.print()
