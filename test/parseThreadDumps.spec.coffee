fs                = require 'fs'
chai              = require 'chai'
sinon             = require 'sinon'
parseThreadDumps  = require '../src/parseThreadDumps.coffee'

expect = chai.expect
chai.use require 'sinon-chai'

# cwd is the javahighcpu dir
describe 'parseThreadDumps', ->
  # TODO Add test cases for bad input
  # TODO Add test cases different types of thread dumps
  it 'parses jstack thread dumps', ->
    fileContents = fs.readFileSync('./test/examples/std/high-cpu-tdumps.out').toString()
    parsedOutput = parseThreadDumps(fileContents)
    #console.log(JSON.stringify(parsedOutput, null, ' '))
    firstDate = '1433881251000'
    expect(parsedOutput[firstDate]["0x61ce"].length).to.eql 4
    expect(parsedOutput[firstDate]["0x611b"].length).to.eql 15

  it 'parses prefixed console thread dumps', ->
    fileContents = fs.readFileSync('./test/examples/console/tdumps_eap6_minimal_logging.txt').toString()
    parsedOutput = parseThreadDumps(fileContents)
    #console.log(JSON.stringify(parsedOutput, null, ' '))
    firstDate = '1422324982000'
    secondDate = '1422325002000'
    expect(Object.keys(parsedOutput).length).to.eql 2
    expect(parsedOutput[firstDate]["0xa284"].length).to.eql 12
    expect(parsedOutput[firstDate]["0xe9e4"].length).to.eql 12
