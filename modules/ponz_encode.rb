


# n は0.1単位
# スキル10.0が知りたいときは n = 100 で呼び出す
def encode_value(n)
  lower = "abcdefghijklmnopqrstuvwxyz"
  upper = "ABCDEF"
  clist = (lower+upper).chars
  p = clist.length
  digit0 = (n/p).to_i
  digit1 = n%p
  clist[digit0] + clist[digit1]
end

# 1ab などを解釈
def decode_skill(str)
  lower = "abcdefghijklmnopqrstuvwxyz"
  upper = "ABCDEF"
  clist = (lower+upper).chars
  res = /([0-9]+)([a-zA-Z]+)/.match(str)
  id = res[1].to_i
  value = clist.index(res[2].chars[0])*clist.length + clist.index(res[2].chars[1])
  value /= 10.0
  name = @skill_list[id]
  return name,value
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
  skill_set = []
  loop do
    if res = fetch_1st(skill) then
      skill_str, other_str = res
      skill_set << decode_skill(skill_str)
      skill = other_str
    else
      break
    end
  end
  return race_name, skill_set
end
