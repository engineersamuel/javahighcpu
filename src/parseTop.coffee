_       = require 'lodash'
moment  = require 'moment'

isValidDate = (d) ->
  if Object::toString.call(d) != '[object Date]'
    return false
  !isNaN(d.getTime())

parseTop = (topOutput, opts) ->
  cpuThreshold = opts?['cpuThreshold'] || 80
  oldDate = new Date(1972, 0, 1)
  output = {}

  # Tue Jun  9 16:20:51 EDT 2015
  fullTimeRe = /\w{3,4} (\w{3,4} {1,2}\d{1,2} \d{2}:\d{2}:\d{2} \w{3,4} \d{4})/i

  for fileLine in topOutput.split("\n")
    line = fileLine.trim()
    if line.length == 0 or line.indexOf('PID') == 0
      continue

    try
      testDate = undefined
      if fullTimeRe.test(line)
        # the index 1 will be the group we want, so instead of: Tue Jun  9 16:20:51 EDT 2015 it will be: Jun  9 16:20:51 EDT 2015
        testDate = new Date(fullTimeRe.exec(line)?[1])
        if not isValidDate(testDate)
          # TODO optimize the exec out
          testDate = moment(fullTimeRe.exec(line)?[1], "MMM D HH:mm:ss ZZ YYYY")?.toDate?()

      if testDate and isValidDate(testDate) and (testDate > oldDate)
        newDate = testDate
        output[+newDate] = {
          'isoDate': newDate.toISOString()
        }
        output[+newDate]['processes'] = {}
        oldDate = newDate
        continue
    catch error
      console.log(error)

    # Only parse the top if there is an actual newDate parsed.
    if not newDate
      continue

    if line.indexOf('top') == 0
      # top - 14:24:13 up 4 days, 18:36, 13 users,  load average: 1.79, 1.68, 1.60
      # grabbing uptime
      output[+newDate]['uptime'] = /up[\s0-9a-zA-Z]+/i.exec(line)?[0]
      # grabbing ldavg data
      ldavg_match = /load average: ([0-9]+.[0-9]+), ([0-9]+.[0-9]+), ([0-9]+.[0-9]+)/i.exec(line)
      output[+newDate]['ldavg'] = {'1 min': ldavg_match?[1], '5 min': ldavg_match?[2], '15 min': ldavg_match?[3]}
      continue
    if line.indexOf('Tasks') == 0 or line.indexOf('Threads') == 0
      # Tasks: 186 total,   1 running, 185 sleeping,   0 stopped,   0 zombie ## RHEL
      # Threads:  41 total,   0 running,  41 sleeping,   0 stopped,   0 zombie ## Fedora
      output[+newDate]['Tasks'] = /([0-9]+ total)/i.exec(line)?[0]
      continue
    if line.indexOf('Cpu') == 0
      # Cpu(s): 17.9%us,  1.3%sy,  0.0%ni, 80.3%id,  0.3%wa,  0.0%hi,  0.2%si,  0.0%st
      usg = /([0-9]+.[0-9]+%)us/i.exec(line)?[1]
      syg = /([0-9]+.[0-9]+%)sy/i.exec(line)?[1]
      idg = /([0-9]+.[0-9]+%)id/i.exec(line)?[1]
      output[+newDate]['Cpu'] = {'us': usg, 'sy': syg, 'id': idg}
      continue
    if line.indexOf('Mem') == 0
      # Mem:  28822876k total, 22717528k used,  6105348k free,   874212k buffers ## RHEL
      mem_match = /([0-9]+)k total.*([0-9]+)k used/i.exec(line)
      totalMem = mem_match[1]
      usedMem = mem_match[2]
      percentUsed = Math.ceil((usedMem / totalMem) * 100)
      output[+newDate]['Mem'] = "#{percentUsed}% used"
      continue
    if line.indexOf('KiB Mem') == 0
      # KiB Mem:  16127716 total, 15760052 used,   367664 free,   374676 buffers ## Fedora
      mem_match = /([0-9]+) total.*([0-9]+) used/i.exec(line)
      totalMem = mem_match[1]
      usedMem = mem_match[2]
      percentUsed = Math.ceil((usedMem / totalMem) * 100)
      output[+newDate]['Mem'] = "#{percentUsed}% used"
      continue
    if line.indexOf('KiB Swap') == 0
      # KiB Swap:  8134652 total,  1218992 used,  6915660 free,  4380324 cached
      swap_match = /([0-9]+) total.*([0-9]+) used/i.exec(line)
      totalSwap = swap_match[1]
      usedSwap = swap_match[2]
      percentUsed = Math.ceil((usedSwap / totalSwap) * 100)
      output[+newDate]['Swap'] = "#{percentUsed}% used"
      continue
    if line.indexOf('Swap') == 0
      # Swap:  1048572k total,    48252k used,  1000320k free,  3801500k cached
      swap_match = /([0-9]+)k total.*([0-9]+)k used/i.exec(line)
      totalSwap = swap_match[1]
      usedSwap = swap_match[2]
      percentUsed = Math.ceil((usedSwap / totalSwap) * 100)
      output[+newDate]['Swap'] = "%s%% used" % percentUsed
      continue

    # 60131 jboss     20   0 6023m 2.6g  19m S  0.0  9.5   0:00.00 /opt/jboss/java/bin/java -D[Server:myl-3-b] -XX:PermSize=256m -X
    # grab CPU data and parse out things we care about
    words = _.chain(line.split(' ')).without(undefined, "").value()

    # Define where the various locations are for what we'll read.  Nearly always the javaProcessLoc is 11, but sometimes it is 10
    pidLoc = 0
    javaProcessLoc = 11
    cpuLoc = 8
    # TODO -- this is more of a brute force approach.  Right now I don't have enough data to need to make it more intelligent
    # Eventually though it would be better to read in the header of the top and determine it that way elsewhere, probably near
    # the top of this function.
    if words.length < 12 and /java/.test(words?[11])
     javaProcessLoc = 10
     cpuLoc = 7
    else if words.length < 12 and /java/.test(words?[8])
      javaProcessLoc = 8
      cpuLoc = 5

    if /java/.test(words[javaProcessLoc])
      pid = words[pidLoc]
      cpu = +words[cpuLoc]
      if cpu >= cpuThreshold
        hexpid = "0x" + Number(pid).toString(16)
        output[+newDate]['processes'][hexpid] =
          'pid': pid
          # http://stackoverflow.com/questions/57803/how-to-convert-decimal-to-hex-in-javascript
          'hexpid': "0x" + Number(pid).toString(16)
          'cpu': cpu
          'mem': words[9]
          'proc_line': line

  if not newDate
    throw Error "Could not parse a timestamp from the top output, please generate top output similar to top -b -n 1 -H -p <pid> >> high-cpu.out"

  return output

module.exports = parseTop
