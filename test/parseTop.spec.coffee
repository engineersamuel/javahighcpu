fs              = require 'fs'
chai            = require 'chai'
sinon           = require 'sinon'
# using compiled JavaScript file here to be sure module works
parseTop        = require '../src/parseTop.coffee'

expect = chai.expect
chai.use require 'sinon-chai'

# cwd is the javahighcpu dir
describe 'parseTop', ->
  # TODO Add test cases for bad input
  it 'parses correctly with a 20% threshold', ->
    fileContents = fs.readFileSync('./test/examples/std/high-cpu.out').toString()
    parsedOutput = parseTop(fileContents, {cpuThreshold: 20})
    #console.log(JSON.stringify(parsedOutput, null, ' '))
    firstDate = '1433881251000'
    expect(parsedOutput[firstDate]["uptime"]).to.eql "up 34 days"
    expect(Object.keys(parsedOutput[firstDate]["processes"]).length).to.eql 2
    expect(parsedOutput[firstDate]["processes"]["0x613f"].cpu).to.eql "45.0"
    expect(parsedOutput[firstDate]["ldavg"]["5 min"]).to.eql "0.47"

  it 'parses correctly with a 50% threshold', ->
    fileContents = fs.readFileSync('./test/examples/std/high-cpu.out').toString()
    parsedOutput = parseTop(fileContents, {cpuThreshold: 50})
    #console.log(JSON.stringify(parsedOutput, null, ' '))
    someDate = '1433881251000'
    expect(parsedOutput[someDate]["uptime"]).to.eql "up 34 days"
    expect(Object.keys(parsedOutput[someDate]["processes"]).length).to.eql 0
    expect(parsedOutput[someDate]["ldavg"]["5 min"]).to.eql "0.47"

    someDate = '1433881283000'
    expect(parsedOutput[someDate]["uptime"]).to.eql "up 34 days"
    expect(Object.keys(parsedOutput[someDate]["processes"]).length).to.eql 1
    expect(parsedOutput[someDate]["processes"]["0x613f"].cpu).to.eql "58.0"
    expect(parsedOutput[someDate]["ldavg"]["5 min"]).to.eql "0.44"
