parseThreadDumps  = require './parseThreadDumps'
parseTop          = require './parseTop'

findOffenders = (topOutput, threadDumpsOutput) ->
  # now that the data has been parsed, read through and find PIDs that exist in multiple dumps
  # iterate over all pids and add them to a dict where the key is the pid and the values are the dumps it came from
  # if there are len(dumps) > 1, then it showed up in multiple and we want to record the thread dumps from those dumps
  # for that pid
  seen = {}

  if not topOutput or not threadDumpsOutput
    return seen

  # limits the depth of java thread stacks
  frameLimit = 10

  for dump in Object.keys(topOutput)
    for hexpid in Object.keys(topOutput[dump]['processes'])
      if dump not in Object.keys(seen)
        seen[dump] = {}
        if hexpid not in seen[dump]
          seen[dump][hexpid] =
            process: undefined
            thread: undefined
      else
        seen[dump][hexpid] =
          process: undefined
          thread: undefined

  itCounter = 1
  for timestamp in Object.keys(seen)
    #console.log "Offending process found in dump #{itCounter} captured @ #{timestamp}"
    itCounter += 1
    processes = topOutput[timestamp]['processes']
    for own hexpid, process of processes
      if seen[timestamp][hexpid]?
        seen[timestamp][hexpid]['process'] = process
        seen[timestamp][hexpid]['thread'] = threadDumpsOutput[timestamp][hexpid]

        #console.log "pid: #{hexpid} was found in seen."
        #console.log proc['proc_line']

#        first = true
#        try
#          # since there are no indexes, I added a counter to track current java frame
#          currFrame = 0
#          for line in threadDumpsOutput[timestamp][hexpid]
#            if first
#              console.log line
#              first = false
#            else
#              if line.indexOf("java.lang.Thread.State") is 0
#                console.log "  #{line}"
#              if line.indexOf("Locked") is 0
#                console.log line
#
#              console.log "\t#{line}"
#
#            # increment counter after each frame and break the loop if its >= the frame_limit
#            currFrame += 1
#            if currFrame >= frameLimit
#              break
#        catch error
#          console.log error

  return seen

module.exports = findOffenders
