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

Any comments, thoughts, or suggestions are welcome.

## <a name="release">Release Notes</a>

### Release 0.0.5

 - Added tests for WorkQueue.

 - Added busy method to Actor.

# Plans and Notes

- pick a problem to test against
 - drop file path into dir_wq
 - pick up and decompose
  - if dir then drop into queue again
  - if file then send to filter actor
   - may need to read start to determine text if no extention
    - check for #! something and assume text/script
    - if not one of know extension then search low chars that are not \n\r\t or other well knows in text
    - cache text if file is read in
  - if text send to through work queue density checker then to summary

 - file density distribution
  - find all files under a directory
  - detemine if the file is a text or bin file and only keep text files
  - read in the text file and on work queue
  - worker determines density of file (non-white/total)
  - pass on to summary actor
  - wait_finish
  - ask to print or write report

- describe patterns for use

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
