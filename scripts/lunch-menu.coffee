CronJob = require('cron').CronJob

module.exports = (robot) ->
  KEY_LUNCH_MENU = 'key_lunch_menu_table'

  getLunchMenus = () ->
    return robot.brain.get(KEY_LUNCH_MENU) or {}

  setLunchMenu = (name, rate) =>
    lunchMenus = getLunchMenus()
    lunchMenus[name] = rate
    robot.brain.set KEY_LUNCH_MENU,lunchMenus 
    return "add: #{name}:#{rate}"

  removeLunchMenu = (name) =>
    lunchMenus = getLunchMenus()
    if lunchMenus[name] != undefined
      delete lunchMenus[name]
      robot.brain.set KEY_LUNCH_MENU,lunchMenus 
      return "remove: #{name}"
    else
      return "no exist"

  robot.hear /list lunch/i, (msg) ->
    lunchMenus = getLunchMenus()
    console.log lunchMenus 
    for name, rate of lunchMenus 
      msg.send "#{name}: #{rate}"

  robot.hear /^set lunch (.+) ([0-9]+)$/i, (msg) ->
    name = msg.match[1]
    rate = msg.match[2]
    result = setLunchMenu(name, rate)
    msg.send "#{result}"

  robot.hear /^rm lunch (.+)$/i, (msg) ->
    name = msg.match[1]
    result = removeLunchMenu(name)
    msg.send "#{result}"

  drawLunchMenus = () ->
    lunchMenus = getLunchMenus()
    if 0 >= Object.keys(lunchMenus).length
      return
    max = 0
    for name, rate of lunchMenus 
      rateNum = parseInt(rate, 10);
      max = max + rateNum
    percentile = Math.floor(Math.random() * max)
    sum = 0
    for name, rate of lunchMenus 
      rateNum = parseInt(rate, 10);
      sum = sum + rateNum
      if sum >= percentile
        return "今日の昼飯は  #{name}"

  new CronJob
    cronTime:'0 0 13 * * 1-5'
    onTick: ->
      result = drawLunchMenus()
      robot.send {room: '#general'}, result
    start: true

  robot.hear /^draw lunch$/i, (msg) ->
    result = drawLunchMenus()
    msg.send "#{result}"
