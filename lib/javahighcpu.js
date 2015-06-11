var findOffenders, parseThreadDumps, parseTop,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  hasProp = {}.hasOwnProperty;

parseThreadDumps = require('./parseThreadDumps');

parseTop = require('./parseTop');

findOffenders = function(topOutput, threadDumpsOutput) {
  var dump, frameLimit, hexpid, i, itCounter, j, k, len, len1, len2, process, processes, ref, ref1, ref2, seen, timestamp;
  seen = {};
  if (!topOutput || !threadDumpsOutput) {
    return seen;
  }
  frameLimit = 10;
  ref = Object.keys(topOutput);
  for (i = 0, len = ref.length; i < len; i++) {
    dump = ref[i];
    ref1 = Object.keys(topOutput[dump]['processes']);
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      hexpid = ref1[j];
      if (indexOf.call(Object.keys(seen), dump) < 0) {
        seen[dump] = {};
        if (indexOf.call(seen[dump], hexpid) < 0) {
          seen[dump][hexpid] = {
            process: void 0,
            thread: void 0
          };
        }
      } else {
        seen[dump][hexpid] = {
          process: void 0,
          thread: void 0
        };
      }
    }
  }
  itCounter = 1;
  ref2 = Object.keys(seen);
  for (k = 0, len2 = ref2.length; k < len2; k++) {
    timestamp = ref2[k];
    itCounter += 1;
    processes = topOutput[timestamp]['processes'];
    for (hexpid in processes) {
      if (!hasProp.call(processes, hexpid)) continue;
      process = processes[hexpid];
      if (seen[timestamp][hexpid] != null) {
        seen[timestamp][hexpid]['process'] = process;
        seen[timestamp][hexpid]['thread'] = threadDumpsOutput[timestamp][hexpid];
      }
    }
  }
  return seen;
};

module.exports = findOffenders;
