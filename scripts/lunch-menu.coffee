CronJob = require('cron').CronJob

module.exports = (robot) ->
  KEY_LUNCH_MENU = 'key_lunch_menu_table'
  KEY_CURRENT_RATE = 'current_rate'
  KEY_INIT_RATE = 'init_rate'
  KEY_VOTE_LUNCH = 'key_vote_lunch'

  getLunchMenus = () ->
    return robot.brain.get(KEY_LUNCH_MENU) or {}

  setLunchMenu = (name, initRate, currentRate) =>
    lunchMenus = getLunchMenus()
    lunchMenus[name] = rate
    robot.brain.set KEY_LUNCH_MENU,lunchMenus 
    return "add: #{name}:#{initRate}, #{currentRate}"

  removeLunchMenu = (name) =>
    lunchMenus = getLunchMenus()
    if lunchMenus[name] != undefined
      delete lunchMenus[name]
      robot.brain.set KEY_LUNCH_MENU,lunchMenus 
      return "remove: #{name}"
    else
      return "no exist"
  
  robot.hear /^list lunch$/i, (msg) ->
    lunchMenus = getLunchMenus()
    menus = '名前 初期weight 現在weight\n'
    for name, rate of lunchMenus 
      menus += "#{name}: #{rate[KEY_INIT_RATE]}, #{rate[KEY_CURRENT_RATE]}\n"
    msg.send menus

  robot.hear /^set lunch (.+) ([0-9]+)$/i, (msg) ->
    name = msg.match[1]
    rate = msg.match[2]
    result = setLunchMenu(name, rate, rate)
    msg.send "#{result}"

  robot.hear /^set lunch (.+) ([0-9]+) ([0-9]+)$/i, (msg) ->
    name = msg.match[1]
    initRate = msg.match[2]
    currentRate = msg.match[3]
    result = setLunchMenu(name, initRate, currentRate)
    msg.send "#{result}"

  robot.hear /^rm lunch (.+)$/i, (msg) ->
    name = msg.match[1]
    result = removeLunchMenu(name)
    msg.send "#{result}" 

  # 抽選処理
  drawLunchMenus = () ->
    lunchMenus = getLunchMenus()
    if 0 >= Object.keys(lunchMenus).length
      return
    max = 0
    for name, rate of lunchMenus
      rateNum = parseInt(rate[KEY_CURRENT_RATE], 10);
      max = max + rateNum
    percentile = Math.floor(Math.random() * max)
    sum = 0
    hitLunch = ''
    result = ''
    for name, rate of lunchMenus
      rateNum = parseInt(rate[KEY_CURRENT_RATE], 10);
      sum = sum + rateNum
      if sum >= percentile
        lunch = {}
        hitLunch = name
        result = "今日の昼飯は  #{name}"
        break
    updateMenuRate(hitLunch)
    return result

  updateMenuRate = (menu) ->
    lunchMenus = getLunchMenus()
    for name, rate of lunchMenus
      if name isnt menu 
        rateNum = parseInt(rate[KEY_CURRENT_RATE], 10);
        lunchMenus[name][KEY_CURRENT_RATE] = (rateNum + 1)
      else
        lunchMenus[name][KEY_CURRENT_RATE] = lunchMenus[name][KEY_INIT_RATE]
    robot.brain.set KEY_LUNCH_MENU,lunchMenus 

  robot.hear /^draw lunch$/i, (msg) ->
    result = drawLunchMenus()
    msg.send "#{result}"

  robot.hear /^convert lunch$/i, (msg) ->
    lunchMenus = getLunchMenus()
    newLunchMenus = {}
    for name, rate of lunchMenus 
      lunch = {}
      lunch[KEY_CURRENT_RATE] = rate
      lunch[KEY_INIT_RATE] = rate
      newLunchMenus[name] = lunch
    result = drawLunchMenus()
    robot.brain.set KEY_LUNCH_MENU,newLunchMenus
    msg.send "convert finish!"

  getVoteLunch = () ->
    return robot.brain.get(KEY_VOTE_LUNCH) or {}

  getVoteLunchResult = () =>
    voteLunch = getVoteLunch()
    result = {}
    for user, menu of voteLunch 
      if result[menu] == undefined
        result[menu] = 1
      else
        result[menu] = parseInt(result[menu], 10) + 1;
    return result

  robot.hear /^list vote lunch$/i, (msg) ->
    voteLunchResult = getVoteLunchResult()
    message = '投票状況\n'
    for menu, point of voteLunchResult 
      message += "#{menu}: #{point}\n"
    msg.send message

  robot.hear /^vote lunch (.+)$/i, (msg) ->
    menu = msg.match[1]
    lunchMenus = getLunchMenus()
    if lunchMenus[menu] == undefined
      msg.send "そんなものはない"
      return
    user = msg.message.user.name
    voteLunch = getVoteLunch()
    voteLunch[user] = menu
    robot.brain.set KEY_VOTE_LUNCH, voteLunch 
    msg.send "#{user} さんが #{menu} に１票"

  robot.hear /^reset vote lunch$/i, (msg) ->
    resetVoteLunch()
    msg.send "reset votes!"

  resetVoteLunch = () ->
    robot.brain.set KEY_VOTE_LUNCH, {} 

  totalVoteLunch = () ->
    voteLunchResult = getVoteLunchResult()
    resultMenu = ''
    max = 0
    for menu, point of voteLunchResult
      pointNum = parseInt(point, 10)
      if pointNum > max
        max = pointNum
        resultMenu = menu
    if max > 0
      updateMenuRate(resultMenu)
      return "投票の結果、今日の昼飯は #{resultMenu} になりました"
    else
      return "投票されませんでした"

  checkVote = () ->
    voteLunch = getVoteLunch()
    return 0 < Object.keys(voteLunch).length

  new CronJob
    cronTime:'0 0 13 * * 1-5'
    onTick: ->
      result = ''
      if checkVote()
        result = totalVoteLunch()
        resetVoteLunch()
      else
        result = drawLunchMenus()
      robot.send {room: '#general'}, result
    start: true

  new CronJob
    cronTime:'0 0 10 * * 1-5'
    onTick: ->
      message = 'メニューに投票してね。なければ天のお告げでランチメニューが決まります\n'
      lunchMenus = getLunchMenus()
      for name, rate of lunchMenus 
        message += "#{name}\n"
      robot.send {room: '#general'}, message
    start: true
