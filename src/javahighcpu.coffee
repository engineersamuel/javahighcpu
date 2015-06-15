parseThreadDumps  = require './parseThreadDumps'
parseTop          = require './parseTop'
_                 = require 'lodash'

findOffenders = (topOutput, threadDumpsOutput) ->
  # now that the data has been parsed, read through and find PIDs that exist in multiple dumps
  # iterate over all pids and add them to a dict where the key is the pid and the values are the dumps it came from
  # if there are len(dumps) > 1, then it showed up in multiple and we want to record the thread dumps from those dumps
  # for that pid
  seen = {}

  # Catalogs the missing data, i.e. where a hexpid wasn't found in a timestamp dump
  missingData = []


  if not topOutput or not threadDumpsOutput
    return seen

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

        if threadDumpsOutput[timestamp]?[hexpid]?
          seen[timestamp][hexpid]['thread'] = threadDumpsOutput[timestamp][hexpid]
        else
          missingData.push
            hexpid: hexpid
            process: process
            timestamp: timestamp

  # The high cpu out and the thread dumps won't always match, warn if not
  # d looks like {
  # hexpid: ...
  # process: ...
  # timestamp: ...
  #}
  for d in missingData

    # Get a list of thread dump timestamps with an ascending order of time deltas compared to this reference:
    timestampDeltas = _.keys(threadDumpsOutput).map((t) -> {timestamp: t, delta: Math.abs(timestamp - t)}).sort((a, b) -> a.delta - b.delta)

    # Iterate over the thread dumps in this order to find the first thread dump that matches the hexpid in question,
    # Then output that with a warning
    _.each timestampDeltas, (t) ->
      timestamp = t.timestamp
      # See if the hexpid in question is in the known hexpids in the threaddump for the particular timestamp
      if d.hexpid in _.keys(threadDumpsOutput[timestamp])
        if not seen[timestamp]
          seen[timestamp] = {}
          seen[timestamp][d.hexpid] = {
            # The delta represents the difference between what is seen in top and the 'matched' thread dumps
            delta: t.delta
            process: d.process
            thread: threadDumpsOutput[timestamp][d.hexpid]
          }
        else if not seen[timestamp][d.hexpid]
          seen[timestamp][d.hexpid] = {
            # The delta represents the difference between what is seen in top and the 'matched' thread dumps
            delta: t.delta
            process: d.process
            thread: threadDumpsOutput[timestamp][d.hexpid]
          }
        else if not seen[timestamp][d.hexpid]['thread']
          seen[timestamp][d.hexpid]['thread'] = threadDumpsOutput[timestamp][d.hexpid]
          seen[timestamp][d.hexpid]['delta'] = t.delta
        else
          console.warn "Found thread #{d.hexpid} using #{d.process.cpu}% CPU but no corresponding thread entry @ #{d.timestamp}".yellow
          console.warn "\tNo corresponding thread entry in any thread dumps".yellow

        return false




  return seen

module.exports = findOffenders
