var _, findOffenders, parseThreadDumps, parseTop,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  hasProp = {}.hasOwnProperty;

parseThreadDumps = require('./parseThreadDumps');

parseTop = require('./parseTop');

_ = require('lodash');

findOffenders = function(topOutput, threadDumpsOutput) {
  var d, dump, hexpid, i, itCounter, j, k, l, len, len1, len2, len3, missingData, process, processes, ref, ref1, ref2, ref3, seen, timestamp, timestampDeltas;
  seen = {};
  missingData = [];
  if (!topOutput || !threadDumpsOutput) {
    return seen;
  }
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
        if (((ref3 = threadDumpsOutput[timestamp]) != null ? ref3[hexpid] : void 0) != null) {
          seen[timestamp][hexpid]['thread'] = threadDumpsOutput[timestamp][hexpid];
        } else {
          missingData.push({
            hexpid: hexpid,
            process: process,
            timestamp: timestamp
          });
        }
      }
    }
  }
  for (l = 0, len3 = missingData.length; l < len3; l++) {
    d = missingData[l];
    timestampDeltas = _.keys(threadDumpsOutput).map(function(t) {
      return {
        timestamp: t,
        delta: Math.abs(timestamp - t)
      };
    }).sort(function(a, b) {
      return a.delta - b.delta;
    });
    _.each(timestampDeltas, function(t) {
      var ref4;
      timestamp = t.timestamp;
      if (ref4 = d.hexpid, indexOf.call(_.keys(threadDumpsOutput[timestamp]), ref4) >= 0) {
        if (!seen[timestamp]) {
          seen[timestamp] = {};
          seen[timestamp][d.hexpid] = {
            delta: t.delta,
            process: d.process,
            thread: threadDumpsOutput[timestamp][d.hexpid]
          };
        } else if (!seen[timestamp][d.hexpid]) {
          seen[timestamp][d.hexpid] = {
            delta: t.delta,
            process: d.process,
            thread: threadDumpsOutput[timestamp][d.hexpid]
          };
        } else if (!seen[timestamp][d.hexpid]['thread']) {
          seen[timestamp][d.hexpid]['thread'] = threadDumpsOutput[timestamp][d.hexpid];
          seen[timestamp][d.hexpid]['delta'] = t.delta;
        } else {
          console.warn(("Found thread " + d.hexpid + " using " + d.process.cpu + "% CPU but no corresponding thread entry @ " + d.timestamp).yellow);
          console.warn("\tNo corresponding thread entry in any thread dumps".yellow);
        }
        return false;
      }
    });
  }
  return seen;
};

module.exports = findOffenders;
