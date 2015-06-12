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

  dateTimeRe = /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/i

  for fileLine in threadDumps.split("\n")
    line = fileLine.trim()

    #if /^201[0-9]+-/i.exec(line) or /^Full thread'/i.exec(line) or line.length is 0
    if dateTimeRe.test(line)
      try
        extractedDateTime = dateTimeRe.exec(line)[0]
        testDate = new Date(extractedDateTime)
        if isValidDate(testDate) and (testDate > oldDate)
          newDate = testDate
          output[+newDate] = {
  #'isoDate': newDate.toISOString()
          }
          oldDate = newDate
          continue
      catch error
        console.log(error)
      finally
        undefined

    # Skip any lines that start with dates or "Full thread" or are empty as they aren't useful
    if /^Full thread'/i.exec(line) or line.length is 0
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
