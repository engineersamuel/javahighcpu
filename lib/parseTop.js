var _, isValidDate, parseTop;

_ = require('lodash');

isValidDate = function(d) {
  if (Object.prototype.toString.call(d) !== '[object Date]') {
    return false;
  }
  return !isNaN(d.getTime());
};

parseTop = function(topOutput, opts) {
  var cpu, cpuThreshold, error, fileLine, hexpid, i, idg, ldavg_match, len, line, mem_match, newDate, oldDate, output, percentUsed, pid, ref, ref1, ref2, ref3, ref4, ref5, swap_match, syg, testDate, totalMem, totalSwap, usedMem, usedSwap, usg, words;
  cpuThreshold = (opts != null ? opts['cpuThreshold'] : void 0) || 80;
  oldDate = new Date(1972, 0, 1);
  output = {};
  ref = topOutput.split("\n");
  for (i = 0, len = ref.length; i < len; i++) {
    fileLine = ref[i];
    line = fileLine.trim();
    if (line.length === 0 || line.indexOf('PID') === 0) {
      continue;
    }
    try {
      testDate = new Date(line);
      if (isValidDate(testDate) && (testDate > oldDate)) {
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
    if (line.indexOf('top') === 0) {
      output[+newDate]['uptime'] = (ref1 = /up[\s0-9a-zA-Z]+/i.exec(line)) != null ? ref1[0] : void 0;
      ldavg_match = /load average: ([0-9]+.[0-9]+), ([0-9]+.[0-9]+), ([0-9]+.[0-9]+)/i.exec(line);
      output[+newDate]['ldavg'] = {
        '1 min': ldavg_match != null ? ldavg_match[1] : void 0,
        '5 min': ldavg_match != null ? ldavg_match[2] : void 0,
        '15 min': ldavg_match != null ? ldavg_match[3] : void 0
      };
      continue;
    }
    if (line.indexOf('Tasks') === 0 || line.indexOf('Threads') === 0) {
      output[+newDate]['Tasks'] = (ref2 = /([0-9]+ total)/i.exec(line)) != null ? ref2[0] : void 0;
      continue;
    }
    if (line.indexOf('Cpu') === 0) {
      usg = (ref3 = /([0-9]+.[0-9]+%)us/i.exec(line)) != null ? ref3[1] : void 0;
      syg = (ref4 = /([0-9]+.[0-9]+%)sy/i.exec(line)) != null ? ref4[1] : void 0;
      idg = (ref5 = /([0-9]+.[0-9]+%)id/i.exec(line)) != null ? ref5[1] : void 0;
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
      mem_match = /([0-9]+) total,\s+([0-9]+) used/i.exec(line);
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
    if (words.length < 12) {
      throw new Error("words array not long enough, tz may not work, line: " + line);
    }
    if (/java/.test(words[11])) {
      pid = words[0];
      cpu = words[8];
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
  return output;
};

module.exports = parseTop;
