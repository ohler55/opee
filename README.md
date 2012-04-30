# Opee gem
An experimental Object-base Parallel Evaluation Environment

The purpose of this gem is to explore setting up an environment that will run
completely in parallel with minimum use of mutex synchronization. Actors only
push the flow forward, never returning values when using the ask()
method. Other methods return immediately but they should never modify the data
portions of the Actors. They can be used to modify the control of the Actor.

Once a reasonable API has been established a high performance C extension will
be written to improve performance.

This is no where close to being ready for prime time.

## <a name="release">Release Notes</a>

### Release 0.0.3

 - Filled out Env and Actor tests.

 - Fixed ordering problem with method execution.


# Plans and Notes

- Log
  - allow forward attribute to be set that forwards messages to another Actor
  - turn output off (useful when there is a forward actor)
  - test
   - set formatter and stringio and test env methods
   - test forwarding

- Env
- Actor

- implement a design pattern for a shared work queue
 - queue is an actor
 - place items on queue either as normal ask sequence or special mutex protected queue
  - if normal then wait for a request for a job and send a job to requestor

- pick a problem to test against
 - checkers
 - process some kind of file
 - process random numbers to produce something
 - life

- describe patterns for use

- Is the notion of a job needed to follow processing of an initial input?
 - avoid using job for storing data though unless rules can be set up to isolate portions of the data to a specific processing path
 - need something for sharing large chunks of data
  - maybe just another actor

### License:

    Copyright (c) 2012, Peter Ohler
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
     - Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer.
    
     - Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.
    
     - Neither the name of Peter Ohler nor the names of its contributors may be
       used to endorse or promote products derived from this software without
       specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
