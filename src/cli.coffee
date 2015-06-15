`#!/usr/bin/env node`

process.bin = process.title = 'javahighcpu';

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

  Usage:
    javahighcpu [-h] [-t 80] [-l 10] [high-cpu.out] [high-cpu.tdump.out]

  Options:
    h         Show this help
    t         CPU Threshold, default: 80 as in 80%
    l         Thread stack length to display, defaults to 10
  Example
    javahighcpu -t 80 high-cpu.out high-cpu.tdump.out

  The top output comes from: top -b -n 1 -H -p <pid> >> high-cpu.out

  The thread dump output comes from jstack -1 <pid> >> high-cpu-tdumps.out

  See the following for generating these files automatically:
    bin/high_cpu_linux_jstack.sh
    bin/high_cpu_linux.sh
"""

# Handle the help option
if cli.flags.h or (not cli.input) or (cli.input.length is 0)
  console.log cli.help
  return

# Validate the high cpu file
try
  fs.lstatSync(cli.input[0])?.isFile()
catch error
  console.error "Not a valid path/file for the high cpu output: #{cli.input[0]}".red
  console.log cli.help
  return

# Validate the thread dumps file
try
  fs.lstatSync(cli.input[1])?.isFile()
catch error
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
catch error
  console.error error.message.red
  console.error "Could not parse thread dumps, please use a file with valid input".red
  return

console.log "Read #{Object.keys(parsedTop).length} top outputs and #{Object.keys(parsedThreadDumps).length} thread dumps.".cyan

# If there is a time delta, that means not an exact match
generateDeltaText = (delta) ->
  if not delta
    return ""
  else
    return "\t(Not an exact top/thread dump match, closest match by #{delta}ms)".red

# If a VM thread is spiked, warn
generateGcText = (text) ->
  if /VM Thread/.test text
    return " (A CPU consuming VM Thread typically indicates a GC issue, please check GC logs)".red
  return ""

# Correlate the top output with the thread dumps and show the offenders
threadLengthDisplay = cli.flags.l || 10
offenders = javahighcpu parsedTop, parsedThreadDumps
if offenders and Object.keys(offenders).length > 0
  for own timestamp, processes of offenders
    d = new Date(+timestamp)

    # Only print the offending process if it was actually found
    if Object.keys(processes).length == 1 and (not processes[Object.keys(processes)[0]].thread)
      continue

    console.log "Found offending processes @ #{d.toLocaleString()}".blue

    for own pid, obj of processes
      proc = obj['process']
      thread = obj['thread']
      console.log "\tpid: #{colors.bold(proc.pid)}\thex: #{colors.bold(proc.hexpid)}\tcpu: #{colors.bold(proc.cpu)}%\tmem: #{colors.bold(proc.mem)}%#{generateDeltaText(obj.delta)}".yellow
      #console.log "\t#{colors.bold(proc.proc_line)}".yellow
      thread?.forEach (stackLine, i) ->
        # Only display n number of stacks, otherwise break
        if (i <= +threadLengthDisplay)
          console.log "\t#{stackLine}#{generateGcText(stackLine)}".cyan
          #console.log "#{if i is 0 then "" else "\t"}\t\t#{stackLine}".cyan
else
  console.log "No high cpu threads within the threshold (#{cpuThreshold}%) specified.".yellow
