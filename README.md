# javahighcpu

[![Dependency status](https://img.shields.io/david/engineersamuel/javahighcpu.svg?style=flat)](https://david-dm.org/engineersamuel/javahighcpu)
[![devDependency Status](https://img.shields.io/david/dev/engineersamuel/javahighcpu.svg?style=flat)](https://david-dm.org/engineersamuel/javahighcpu#info=devDependencies)
[![Build Status](https://img.shields.io/travis/engineersamuel/javahighcpu.svg?style=flat&branch=master)](https://travis-ci.org/engineersamuel/javahighcpu)

[![NPM](https://nodei.co/npm/javahighcpu.svg?style=flat)](https://npmjs.org/package/javahighcpu)

## Installation

    npm install -g javahighcpu

## Usage

Correlates top output with thread dumps.
This tool was inspired from [Java application high CPU](https://access.redhat.com/solutions/24830) and [How do I identify high CPU utilization by Java threads on Linux/Solaris](https://access.redhat.com/solutions/46596)

The top output comes from: `top -b -n 1 -H -p <pid> >> high-cpu.out`

The thread dump output comes from `jstack -1 <pid> >> high-cpu-tdumps.out`

However it is generally recommended to generate this data from the script in the bin dir:
`bin/high_cpu_linux_jstack.sh <pid>`

## Usage Example

Attempt to correlate top output and thread dumps with a CPU threshold of 80%.  This will output any threads that are engaging the CPU at 80%.

    javahighcpu high-cpu.out high-cpu.tdump.out
    
    
![Usage Example Screen](https://cloud.githubusercontent.com/assets/2019830/8115433/46fd9324-1049-11e5-8451-32a994af4164.png)
    
## Testing

    npm test
    
## Contributing

    grunt dev
    node lib/cli.js -t 10 test/examples/std/high-cpu.out test/examples/std/high-cpu-tdumps.out
    
### Release process

    gulp nodify
    npm run test
    npm run patch-release

## License

The MIT License (MIT)

Copyright 2015 Samuel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
