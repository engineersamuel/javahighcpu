fs                = require 'fs'
chai              = require 'chai'
sinon             = require 'sinon'
#javahighcpu       = require '../src/javahighcpu.coffee'
javahighcpu       = require '../lib/javahighcpu'
parseTop          = require '../src/parseTop.coffee'
parseThreadDumps  = require '../src/parseThreadDumps.coffee'

expect = chai.expect
chai.use require 'sinon-chai'

# cwd is the javahighcpu dir
describe 'javahighcpu', ->
  it 'identify offenders at 20%', ->
    fileContents = fs.readFileSync('./test/examples/high-cpu.out').toString()
    parsedTop = parseTop(fileContents, {cpuThreshold: 20})
    fileContents = fs.readFileSync('./test/examples/high-cpu-tdumps.out').toString()
    parsedThreadDumps = parseThreadDumps(fileContents)

    offendersOutput = javahighcpu(parsedTop, parsedThreadDumps)
    #console.log(JSON.stringify(offendersOutput, null, ' '))
    firstDate = '1433881251000'
    expect(offendersOutput[firstDate]["0x60ec"]["process"]["cpu"]).to.eql "23.0"
    expect(offendersOutput[firstDate]["0x613f"]["process"]["cpu"]).to.eql "45.0"

  it 'identify offenders at 50%', ->
    fileContents = fs.readFileSync('./test/examples/high-cpu.out').toString()
    parsedTop = parseTop(fileContents, {cpuThreshold: 50})
    fileContents = fs.readFileSync('./test/examples/high-cpu-tdumps.out').toString()
    parsedThreadDumps = parseThreadDumps(fileContents)

    offendersOutput = javahighcpu(parsedTop, parsedThreadDumps)
    #console.log(JSON.stringify(offendersOutput, null, ' '))
    firstDate = '1433881272000'
    expect(offendersOutput[firstDate]["0x613f"]["process"]["cpu"]).to.eql "55.0"
    expect(offendersOutput[firstDate]["0x613f"]["thread"].length).to.eql 9

  it 'Should not fail if nothing identified at 99%', ->
    fileContents = fs.readFileSync('./test/examples/high-cpu.out').toString()
    parsedTop = parseTop(fileContents, {cpuThreshold: 99})
    fileContents = fs.readFileSync('./test/examples/high-cpu-tdumps.out').toString()
    parsedThreadDumps = parseThreadDumps(fileContents)

    offendersOutput = javahighcpu(parsedTop, parsedThreadDumps)
    expect(Object.keys(offendersOutput ).length).to.eql 0
