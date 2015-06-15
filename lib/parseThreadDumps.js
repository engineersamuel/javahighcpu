var _, isValidDate, moment, parseThreadDumps;

_ = require('lodash');

moment = require('moment');

isValidDate = function(d) {
  if (Object.prototype.toString.call(d) !== '[object Date]') {
    return false;
  }
  return !isNaN(d.getTime());
};

parseThreadDumps = function(threadDumps) {
  var dateTimeRe, error, extractedDateTime, fileLine, fullTimeRe, i, len, line, lineNum, newDate, oldDate, output, ref, ref1, ref2, ref3, ref4, splitThreadDump, stackId, testDate;
  output = {};
  oldDate = new Date(1972, 0, 1);
  stackId = 0;
  dateTimeRe = /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/i;
  fullTimeRe = /\w{3,4} (\w{3,4} {1,2}\d{1,2} \d{2}:\d{2}:\d{2} \w{3} \d{4})/i;
  lineNum = 0;
  splitThreadDump = threadDumps.split("\n");
  for (i = 0, len = splitThreadDump.length; i < len; i++) {
    fileLine = splitThreadDump[i];
    lineNum = lineNum + 1;
    line = fileLine.trim();
    if (fullTimeRe.test(line) || dateTimeRe.test(line)) {
      if (dateTimeRe.test(line) && (fullTimeRe.test(splitThreadDump[lineNum - 2]))) {
        continue;
      }
      try {
        extractedDateTime = ((ref = fullTimeRe.exec(line)) != null ? ref[1] : void 0) || ((ref1 = dateTimeRe.exec(line)) != null ? ref1[1] : void 0);
        testDate = new Date(extractedDateTime);
        if (!isValidDate(testDate)) {
          testDate = (ref2 = moment((ref3 = fullTimeRe.exec(line)) != null ? ref3[1] : void 0, "MMM D HH:mm:ss ZZ YYYY")) != null ? typeof ref2.toDate === "function" ? ref2.toDate() : void 0 : void 0;
        }
        if (testDate && isValidDate(testDate) && (testDate > oldDate)) {
          newDate = testDate;
          output[+newDate] = {};
          oldDate = newDate;
          continue;
        }
      } catch (_error) {
        error = _error;
        console.log(error);
      }
    }
    if (/.*?Full thread'/i.exec(line) || line.length === 0) {
      continue;
    }
    if (/nid=(0x[0-9a-zA-Z]+)/i.test(line)) {
      stackId = /nid=(0x[0-9a-zA-Z]+)/i.exec(line)[1];
      output[+newDate][stackId] = [line];
    } else if (newDate && (((ref4 = output[+newDate]) != null ? ref4[stackId] : void 0) != null)) {
      output[+newDate][stackId].push(line);
    }
  }
  return output;
};

module.exports = parseThreadDumps;
