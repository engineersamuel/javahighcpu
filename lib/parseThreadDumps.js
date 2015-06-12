var _, isValidDate, parseThreadDumps;

_ = require('lodash');

isValidDate = function(d) {
  if (Object.prototype.toString.call(d) !== '[object Date]') {
    return false;
  }
  return !isNaN(d.getTime());
};

parseThreadDumps = function(threadDumps) {
  var dateTimeRe, error, extractedDateTime, fileLine, i, len, line, newDate, oldDate, output, ref, ref1, stackId, testDate;
  output = {};
  oldDate = new Date(1972, 0, 1);
  stackId = 0;
  dateTimeRe = /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/i;
  ref = threadDumps.split("\n");
  for (i = 0, len = ref.length; i < len; i++) {
    fileLine = ref[i];
    line = fileLine.trim();
    if (dateTimeRe.test(line)) {
      try {
        extractedDateTime = dateTimeRe.exec(line)[0];
        testDate = new Date(extractedDateTime);
        if (isValidDate(testDate) && (testDate > oldDate)) {
          newDate = testDate;
          output[+newDate] = {};
          oldDate = newDate;
          continue;
        }
      } catch (_error) {
        error = _error;
        console.log(error);
      } finally {
        void 0;
      }
    }
    if (/^Full thread'/i.exec(line) || line.length === 0) {
      continue;
    }
    if (/nid=(0x[0-9a-zA-Z]+)/i.test(line)) {
      stackId = /nid=(0x[0-9a-zA-Z]+)/i.exec(line)[1];
      output[+newDate][stackId] = [line];
    } else if (newDate && (((ref1 = output[+newDate]) != null ? ref1[stackId] : void 0) != null)) {
      output[+newDate][stackId].push(line);
    }
  }
  return output;
};

module.exports = parseThreadDumps;
