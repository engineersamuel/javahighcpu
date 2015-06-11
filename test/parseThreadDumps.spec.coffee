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
  it 'parses thread dumps', ->
    fileContents = fs.readFileSync('./test/examples/high-cpu-tdumps.out').toString()
    parsedOutput = parseThreadDumps(fileContents)
#    console.log(JSON.stringify(parsedOutput, null, ' '))
    firstDate = '1433881251000'
    expect(parsedOutput[firstDate]["0x61ce"].length).to.eql 4
    expect(parsedOutput[firstDate]["0x611b"].length).to.eql 15
