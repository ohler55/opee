# Opee gem
An experimental Object-based Parallel Evaluation Environment

The purpose of this gem is to explore setting up an environment that will run
completely in parallel with minimum use of mutex synchronization. Actors only
push the flow forward, never returning values when using the ask()
method. Other methods return immediately but they should never modify the data
portions of the Actors. They can be used to modify the control of the Actor.

Once a reasonable API has been established a high performance C extension will
be written to improve performance.

Give it a try. Any comments, thoughts, or suggestions are welcome.

## <a name="source">Source</a>

*GitHub* *repo*: https://github.com/ohler55/opee

*RubyGems* *repo*: https://rubygems.org/gems/opee

## <a name="links">Links of Interest</a>

[Not Your Usual Threading](http://www.ohler.com/dev/not_your_usual_threading/not_your_usual_threading.html) discussion about how OPEE use changes the way multi-threaded systems are designed.

[Open Remote Encrypted File Synchronization](http://www.ohler.com/orefs) is a sample application that makes use of the Opee gem.

## <a name="release">Release Notes</a>

### Release 1.0.4

 - Fixed a bug in queue size reporting for the Queue class.

# Plans and Notes

- implement in C if there is enough interest

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
