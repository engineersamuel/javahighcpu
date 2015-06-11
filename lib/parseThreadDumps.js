var _, isValidDate, parseThreadDumps;

_ = require('lodash');

isValidDate = function(d) {
  if (Object.prototype.toString.call(d) !== '[object Date]') {
    return false;
  }
  return !isNaN(d.getTime());
};

parseThreadDumps = function(threadDumps) {
  var error, fileLine, i, len, line, newDate, oldDate, output, ref, stackId, testDate;
  output = {};
  oldDate = new Date(1972, 0, 1);
  stackId = 0;
  ref = threadDumps.split("\n");
  for (i = 0, len = ref.length; i < len; i++) {
    fileLine = ref[i];
    line = fileLine.trim();
    if (/^201[0-9]+-/i.exec(line) || /^Full thread'/i.exec(line) || line.length === 0) {
      continue;
    }
    try {
      testDate = new Date(line);
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
    if (line.indexOf('"') === 0) {
      stackId = /nid=(0x[0-9a-zA-Z]+)/i.exec(line)[1];
      output[+newDate][stackId] = [line];
    } else if (output[+newDate][stackId] != null) {
      output[+newDate][stackId].push(line);
    }
  }
  return output;
};

module.exports = parseThreadDumps;
