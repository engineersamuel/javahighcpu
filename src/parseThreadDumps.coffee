_   = require('lodash')

isValidDate = (d) ->
  if Object::toString.call(d) != '[object Date]'
    return false
  !isNaN(d.getTime())

parseThreadDumps = (threadDumps) ->
  # output will be keyed on date
  output = {}

  oldDate = new Date(1972, 0, 1)

  stackId = 0

  # 2015-06-09 16:20:52
  dateTimeRe = /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/i

  # Tue Jun  9 16:20:51 EDT 2015
  fullTimeRe = /(\w{3,4} \w{3,4} {1,2}\d{1,2} \d{2}:\d{2}:\d{2} \w{3} \d{4})/i

  lineNum = 0
  splitThreadDump = threadDumps.split("\n")
  for fileLine in splitThreadDump
    lineNum = lineNum + 1
    line = fileLine.trim()

    # The fullTimeRe is the preferred line that will most commonly be seen, however sometimes the file will start with:
    # Tue Jun  9 16:20:51 EDT 2015  # This will be the preferred date in parsing
    # 2015-06-09 16:20:52
    if fullTimeRe.test(line) or dateTimeRe.test(line)

      # Only use the shortened date format if the previous line isn't the full date format
      # There are some thread dumps that only contain this dateTimeRe, in that case, this will match fine and the previous
      # but preferred one won't
      if dateTimeRe.test(line) and (fullTimeRe.test(splitThreadDump[lineNum - 2]))
        continue

      try
        # Always prefer the fullTimeRe first, but it isn't always there, so failover to the dateTimeRe.
        extractedDateTime = fullTimeRe.exec(line)?[0] || dateTimeRe.exec(line)?[0]
        testDate = new Date(extractedDateTime)
        if isValidDate(testDate) and (testDate > oldDate)
          newDate = testDate
          output[+newDate] = {}
          oldDate = newDate
          continue
      catch error
        console.log(error)

#    if dateTimeRe.test(line) and (fullTimeRe.test(splitThreadDump[lineNum - 1]))
#      try
#        extractedDateTime = dateTimeRe.exec(line)[0]
#        testDate = new Date(extractedDateTime)
#        if isValidDate(testDate) and (testDate > oldDate)
#          newDate = testDate
#          output[+newDate] = {}
#          oldDate = newDate
#          continue
#      catch error
#        console.log(error)

    # Skip any lines that start with dates or "Full thread" or are empty as they aren't useful
    if /.*?Full thread'/i.exec(line) or line.length is 0
      continue

    #line.indexOf('"') is 0 # previously this was the match context, but some thread dumps have prefixes, not all are
    # so clean as to have "
    if /nid=(0x[0-9a-zA-Z]+)/i.test(line)
      stackId = /nid=(0x[0-9a-zA-Z]+)/i.exec(line)[1]
      output[+newDate][stackId] = [line]
    # Must ensure that the array is created before pushing to it.
    else if newDate and output[+newDate]?[stackId]?
      output[+newDate][stackId].push line

  return output


module.exports = parseThreadDumps
