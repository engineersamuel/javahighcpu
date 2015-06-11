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

  for fileLine in threadDumps.split("\n")
    line = fileLine.trim()

    # Skip any lines that start with dates or "Full thread" as they aren't useful
    if /^201[0-9]+-/i.exec(line) or /^Full thread'/i.exec(line) or line.length is 0
      continue

    try
      testDate = new Date(line)
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

    if line.indexOf('"') is 0
      stackId = /nid=(0x[0-9a-zA-Z]+)/i.exec(line)[1]
      output[+newDate][stackId] = [line]
    # Must ensure that the array is created before pushing to it.
    else if output[+newDate][stackId]?
      output[+newDate][stackId].push line

  return output


module.exports = parseThreadDumps
