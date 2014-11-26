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
    if 'lunchMenus[name] != null'
      lunchMenus.remove(name)
      robot.brain.set KEY_LUNCH_MENU,lunchMenus 
      return "remove: #{name}"
    else
      return "no exist"

  robot.hear /list lunch menu/i, (msg) ->
    lunchMenus = getLunchMenus()
    console.log lunchMenus 
    for name, rate of lunchMenus 
      msg.send "#{name}: #{rate}"

  robot.hear /^add lunch menu (.+) ([0-9]+)$/i, (msg) ->
    name = msg.match[1]
    rate = msg.match[2]
    result = setLunchMenu(name, rate)
    msg.send "#{result}"

  robot.hear /^remove lunch menu (.+)$/i, (msg) ->
    name = msg.match[1]
    result = removeLunchMenu(name)
    msg.send "#{result}"

  new CronJob
    cronTime:'0 * * * * 1-5'
    onTick: ->
      lunchMenus = getLunchMenus()
      max = 0
      for name, rate of lunchMenus 
        max += rate
      percentile = Math.floor(Math.random() * max)
      sum = 0
      for name, rate of lunchMenus 
        sum += rate
        if sum >= percentile
          robot.send {room: ''}, "today lunch is #{name}"
          return
    start: true
