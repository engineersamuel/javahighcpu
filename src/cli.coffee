`#!/usr/bin/env node`

fs                = require 'fs'
colors            = require 'colors'
meow              = require 'meow'
javahighcpu       = require './javahighcpu'
parseTop          = require './parseTop'
parseThreadDumps  = require './parseThreadDumps'

cli = meow
  pkg: require "../package.json"
  help: """
  Correlates top output with thread dumps.
  This tool was inspired from https://access.redhat.com/solutions/24830 (Java application high CPU) and https://access.redhat.com/solutions/46596 (How do I identify high CPU utilization by Java threads on Linux/Solaris)

  The top output comes from: top -b -n 1 -H -p <pid> >> high-cpu.out

  The thread dump output comes from jstack -1 <pid> >> high-cpu-tdumps.out

  See the following for generating these files automatically:
    bin/high_cpu_linux_jstack.sh
    bin/high_cpu_linux.sh


  Usage:
    javahighcpu [-h] [-t 80] [high-cpu.out] [high-cpu.tdump.out]

  Options:
    h         Show this help
    t         CPU Threshold, default: 80 as in 80%

  Example
    javahighcpu -t 80 high-cpu.out high-cpu.tdump.out
"""

# Handle the help option
if cli.flags.h
  console.log cli.help
  return

# Validate the high cpu file
try
  fs.lstatSync(cli.input[0])?.isFile()
catch
  console.error "Not a valid path/file for the high cpu output: #{cli.input[0]}".red
  console.log cli.help
  return

# Validate the thread dumps file
try
  fs.lstatSync(cli.input[1])?.isFile()
catch
  console.error "Not a valid path/file for the thread dumps: #{cli.input[0]}".red
  console.log cli.help
  return

# Parse the top output
cpuThreshold = cli.flags.t || 80
parsedTop = {}
try
  parsedTop = parseTop(fs.readFileSync(cli.input[0]).toString(), {cpuThreshold: cpuThreshold})
catch error
  console.error error.message.red
  console.error "Could not parse high cpu top output, please use a file with valid input".red
  return

# Parse the thread dumps
parsedThreadDumps = {}
try
  parsedThreadDumps = parseThreadDumps(fs.readFileSync(cli.input[1]).toString())
catch
  console.error error.message.red
  console.error "Could not parse thread dumps, please use a file with valid input".red
  return

console.log "Read #{Object.keys(parsedTop).length} top outputs and #{Object.keys(parsedThreadDumps).length} thread dumps.".cyan

# Correlate the top output with the thread dumps and show the offenders
offenders = javahighcpu parsedTop, parsedThreadDumps
if offenders and Object.keys(offenders).length > 0
  for own timestamp, processes of offenders
    d = new Date(+timestamp)
    console.log "Found offending processes @ #{d.toLocaleString()}".blue
    for own pid, obj of processes
      proc = obj['process']
      thread = obj['thread']
      console.log "\tpid: #{colors.bold(proc.pid)}\thex: #{colors.bold(proc.hexpid)}\tcpu: #{colors.bold(proc.cpu)}%\tmem: #{colors.bold(proc.mem)}%".yellow
      #console.log "\t#{colors.bold(proc.proc_line)}".yellow
      thread?.forEach (stackLine, i) ->
        console.log "#{if i is 0 then "" else "\t"}\t\t#{stackLine}".cyan
else
  console.log "No high cpu threads within the threshold (#{cpuThreshold}%) specified.".yellow
