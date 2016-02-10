var _, isValidDate, moment, parseTop;

_ = require('lodash');

moment = require('moment');

isValidDate = function(d) {
  if (Object.prototype.toString.call(d) !== '[object Date]') {
    return false;
  }
  return !isNaN(d.getTime());
};

parseTop = function(topOutput, opts) {
  var cpu, cpuLoc, cpuThreshold, error, fileLine, fullTimeRe, hexpid, i, idg, javaProcessLoc, ldavg_match, len, line, mem_match, newDate, oldDate, output, percentUsed, pid, pidLoc, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, swap_match, syg, testDate, totalMem, totalSwap, usedMem, usedSwap, usg, words;
  cpuThreshold = (opts != null ? opts['cpuThreshold'] : void 0) || 80;
  oldDate = new Date(1972, 0, 1);
  output = {};
  fullTimeRe = /\w{3,4} (\w{3,4} {1,2}\d{1,2} \d{2}:\d{2}:\d{2} \w{3,4} \d{4})/i;
  ref = topOutput.split("\n");
  for (i = 0, len = ref.length; i < len; i++) {
    fileLine = ref[i];
    line = fileLine.trim();
    if (line.length === 0 || line.indexOf('PID') === 0) {
      continue;
    }
    try {
      testDate = void 0;
      if (fullTimeRe.test(line)) {
        testDate = new Date((ref1 = fullTimeRe.exec(line)) != null ? ref1[1] : void 0);
        if (!isValidDate(testDate)) {
          testDate = (ref2 = moment((ref3 = fullTimeRe.exec(line)) != null ? ref3[1] : void 0, "MMM D HH:mm:ss ZZ YYYY")) != null ? typeof ref2.toDate === "function" ? ref2.toDate() : void 0 : void 0;
        }
      }
      if (testDate && isValidDate(testDate) && (testDate > oldDate)) {
        newDate = testDate;
        output[+newDate] = {
          'isoDate': newDate.toISOString()
        };
        output[+newDate]['processes'] = {};
        oldDate = newDate;
        continue;
      }
    } catch (_error) {
      error = _error;
      console.log(error);
    }
    if (!newDate) {
      continue;
    }
    if (line.indexOf('top') === 0) {
      output[+newDate]['uptime'] = (ref4 = /up[\s0-9a-zA-Z]+/i.exec(line)) != null ? ref4[0] : void 0;
      ldavg_match = /load average: ([0-9]+.[0-9]+), ([0-9]+.[0-9]+), ([0-9]+.[0-9]+)/i.exec(line);
      output[+newDate]['ldavg'] = {
        '1 min': ldavg_match != null ? ldavg_match[1] : void 0,
        '5 min': ldavg_match != null ? ldavg_match[2] : void 0,
        '15 min': ldavg_match != null ? ldavg_match[3] : void 0
      };
      continue;
    }
    if (line.indexOf('Tasks') === 0 || line.indexOf('Threads') === 0) {
      output[+newDate]['Tasks'] = (ref5 = /([0-9]+ total)/i.exec(line)) != null ? ref5[0] : void 0;
      continue;
    }
    if (line.indexOf('Cpu') === 0) {
      usg = (ref6 = /([0-9]+.[0-9]+%)us/i.exec(line)) != null ? ref6[1] : void 0;
      syg = (ref7 = /([0-9]+.[0-9]+%)sy/i.exec(line)) != null ? ref7[1] : void 0;
      idg = (ref8 = /([0-9]+.[0-9]+%)id/i.exec(line)) != null ? ref8[1] : void 0;
      output[+newDate]['Cpu'] = {
        'us': usg,
        'sy': syg,
        'id': idg
      };
      continue;
    }
    if (line.indexOf('Mem') === 0) {
      mem_match = /([0-9]+)k total,\s+([0-9]+)k used/i.exec(line);
      totalMem = mem_match[1];
      usedMem = mem_match[2];
      percentUsed = Math.ceil((usedMem / totalMem) * 100);
      output[+newDate]['Mem'] = percentUsed + "% used";
      continue;
    }
    if (line.indexOf('KiB Mem') === 0) {
      mem_match = /([0-9]+) total.*([0-9]+) used/i.exec(line);
      totalMem = mem_match[1];
      usedMem = mem_match[2];
      percentUsed = Math.ceil((usedMem / totalMem) * 100);
      output[+newDate]['Mem'] = percentUsed + "% used";
      continue;
    }
    if (line.indexOf('KiB Swap') === 0) {
      swap_match = /([0-9]+) total.*([0-9]+) used/i.exec(line);
      totalSwap = swap_match[1];
      usedSwap = swap_match[2];
      percentUsed = Math.ceil((usedSwap / totalSwap) * 100);
      output[+newDate]['Swap'] = percentUsed + "% used";
      continue;
    }
    if (line.indexOf('Swap') === 0) {
      swap_match = /([0-9]+)k total.*([0-9]+)k used/i.exec(line);
      totalSwap = swap_match[1];
      usedSwap = swap_match[2];
      percentUsed = Math.ceil((usedSwap / totalSwap) * 100);
      output[+newDate]['Swap'] = "%s%% used" % percentUsed;
      continue;
    }
    words = _.chain(line.split(' ')).without(void 0, "").value();
    pidLoc = 0;
    javaProcessLoc = 11;
    cpuLoc = 8;
    if (words.length < 12 && /java/.test(words != null ? words[11] : void 0)) {
      javaProcessLoc = 10;
      cpuLoc = 7;
    } else if (words.length < 12 && /java/.test(words != null ? words[8] : void 0)) {
      javaProcessLoc = 8;
      cpuLoc = 5;
    }
    if (/java/.test(words[javaProcessLoc])) {
      pid = words[pidLoc];
      cpu = words[cpuLoc];
      if (cpu >= cpuThreshold) {
        hexpid = "0x" + Number(pid).toString(16);
        output[+newDate]['processes'][hexpid] = {
          'pid': pid,
          'hexpid': "0x" + Number(pid).toString(16),
          'cpu': cpu,
          'mem': words[9],
          'proc_line': line
        };
      }
    }
  }
  if (!newDate) {
    throw Error("Could not parse a timestamp from the top output, please generate top output similar to top -b -n 1 -H -p <pid> >> high-cpu.out");
  }
  return output;
};

module.exports = parseTop;
