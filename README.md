<style>
.method {
  color: orangered;
  font-family: Courier;
}
.header {
  color: green;
}
.param_header {
  margin: 0em;
  font-weight: bold;
  color: dimgray;
}
.param {
  color: blue;
}
.type {
  color: dimgray;
  font-style: italic;
}
body {
  font-family: times;
  padding-left: 1em; 
  background-color: ghostwhite;
}
.ex {
  background-color: black;
  color: white;
  padding: 1em;
  font-family: Courier;
  margin-left: 4em;
  width: 70em;
  font-size: 0.9em;
  white-space: pre;
}
.eh {
  color: lightblue;
}
.em {
  color: orange;
}
.terminal {
  background-color: white;
  border: dashed 1px black;
  padding: 1em;
  font-family: Courier;
  margin-left: 4em;
  width: 40em;
}
</style>

<h1 style="color: orangered;">SimpleRotate</h1>
SimpleRotate is a library that output the log messages to a file and roatate it.  

Version: 1.0.0  
Compliant Ruby Versions: 1.9.3, 2.0.0, 2.1.0 (for Linux)  
License: MIT  
Gems repository: http://rubygems.org (<a href="http://rubygems.org/gems/simple_rotate">http://rubygems.org/gems/simple_rotate</a>)  

<h2 class="header">Installation</h2>
It can be installed using the gem command.
<p class="terminal">
$ gem install simple\_rotate
</p>

Need "#reqire" because it is an external library.
<p class="terminal">
require 'simple_rotate'
</p>


<h2 class="header" id="multi">Tips</h2>
### About multi thread, multi process  
* Multi Thread  
SimpleRotate supports thread safe.  
Process to open a file, create a new, Rotate, and write the log is exclusive control by Mutex.  
Attempts to sync to be able to write to the new file always checks the inode number at the time of writing.   
This mode is enabled by default.  
You can skip to confirm the synchronization of the inode number if the call \#no\_sync\_inode method,  
but is not recommended in the case of multiple threads and multiple processes.  

* Multi Process  
It to be the "process safe mode" when you call the \#psafe\_mode method.   
If you enable this mode, Process of writing the log, such as the rotation of the file will be exclusive lock between processes.  
Attempts to sync to be able to write to the new file always checks the inode number at the time of writing.  
It will flush the internal buffer of the I/O port after the write.   
This feature is implemented by ProcessSync class is an internal class of SimpleRotate.    
Three times to try to get the lock again unexpected error process between exclusive lock acquisition occurs.   
Make the process not get lock third fails.   
If process safe mode is enabled, Temporary file will be created at the same directory as the log file, and It is scheduled to be removed at the end of Ruby script.  
It will be named .SimpleRotate\_tempfile\_[script\_file\_name].  
Delete will not run if there is no permission to delete or if it is not empty temporary file in or termination if a file with the same name already exists.   

<h2 class="header">Usage</h2>

### Public Class Methods
* <span class="method">instance</span>  
Return the SimpleRotate object.  
SimpleRotate Class has been implemented in the Singleton pattern.  
Therefore object to return SimpleRotate is the only object.  
It is error to use the new method because it can not access from the object initilize method now private.  

### Public Instance Methods
* <span class="method">init([file\_name, [limit, [generation]]])</span>   
Make configure for logging.  
The settings you make here, the object returned by SimpleRotate::instance after also continues to hold.  
It will return "self".  

<div class="param_header">Parameters</div>
  * <span class="type">String|Symbol</span> <span class="param">file\_name="./file\_name.log"</span>  
Specifies the name of the file to the output log message relative path or absolute  path.   
If the same file as the file that you specify here is present, add writing to the file.  
If you want to output to standard output only,  Specifies the :STDOUT by Simbol.  
<br />
  * <span class="type">Integer|String</span> <span class="param">limit="1M"</span>  
Specifies the maximum size of the log file.  
Size of the log file is evaluated by #init, #w methods.  
If the log file have exceeded the set value specified here, it is written to the next file.   
At that time, the old file name will be renamed in this way.  
file\_name.1、file\_name.2、file\_name.3、file\_name.4  
Old number will be written about the old file.  
Specifies a string such as "1G" or numbers,. "K", "M", "G" will be recognized.  
The log file is written to the next file when it exceeds the size 1M, Because it is "1M" default.  
<br />
It is also possible to rotate by a certain period of time, If specified "DAILY" or "WEEKLY" or "MONTHLY".  
If specfied "DAILY":  The log file will be rotated once every other day.   
If specfied "WEEKLY":  The log file will be rotated every 7 days.  
If specfied "MONTHLY":  The log file will be rotated every 30 days.  
Old file name is renamed to file\_name.YYYYmmdd at the rotation.  
<br />
   * <span class="type">Integer</span> <span class="param">generation=0</span>  
The maximum number of old log files.  
Old log files will be a generational change in the number that you specify here.   
For example, if you set the this parameter to 4,  
Old log files will be created up to 4 generations: file\_name.1, file\_name.2, file\_name.3, the file\_name.4.   
In this case, will be rotated in up to 5 files, contains the most recent log file.  
No generation change if you set the value to 0.    
Default is 0.   

You can also call #init with block.   
Close the I/O port of the log file automatically when you exit the block.   
<p class="ex"><span class="eh">example:</span>
logger = SimpleRotate.instance
logger.init("foo.log") do |sr|
  sr << "log message"
end
logger.init("bar.log") do |sr|
  sr << "log message"
end
</p>


* <span class="method">with\_stdout</span>  
Log message is also output to STDOUT.  

* <span class="method">compress</span>  
To gzip compress the old log file when it rotates.   
'zlib' library is loaded.   
Default does not perform compression.   
Should be done before for call #init, Because there is a possibility that the rotation is performed in the #init.   

* <span class="method">compress\_level(level)</span>  
Specifies the compression level.   
Degree of compression will increase the number the higher.  
The default compression level is Zlib::DEFAULT\_COMPRESSION.   
Compression switches to enable when you call to this method.   
Return the level.  
Should be done before for call #init, Because there is a possibility that the rotation is performed in the #init.   
<div class="param_header">Parameters</div>  
  * <span class="type">Integer</span> <span class="param">lelvel</span>  
Specifies a number between 0-9 compression level.  

* <span class="method">w(message)</span>  
Write the log messages to the log file.   
Log messages will have the information in the log level.   
Log level is determined (#debug, #info, #warn, #error, #fatal) in a method that determines the log level that was most recently executed.  
The object that is not called even once these methods for determining the log level, It will has log level a "INFO".   
<div class="param_header">Parameters</div>  
  * <span class="type">mixed</span> <span class="param">message</span>  
Specifies the log message to be output to the file.    
It does not matter as Integer and Float without a String.    
It is also possible to specify an Array.   

<p class="ex"><span class="eh">example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log")
ary = [111, 333, 555]
logger.w ary
logger.error.w("foo bar")

  <span class="em">It is output to the log file as described below.</span>
<span style="color: yellow;">[2014/01/15 19:44:22] - INFO : [111, 333, 555]   
[2014/01/15 19:44:22] - ERROR : foo bar</span>
</p>


* <span class="method">&lt;&lt; message</span>  
Alias of the #w method.


* <span class="method">enable\_wflush</span>  
Flush the internal buffer of the I/O port after calling #w.


* <span class="method">disable\_wflush</span>  
Dose not flush the internal buffer of the I/O port after calling #w.  
This is default.


* <span class="method">e</span>  
Close the I/O ports of the log file.  
It will returns nil if you have specified the ':STDOUT' to the 'file\_name' parameters of #init.  


* <span class="method">reopen</span>  
Reopen the I/O port of the log file closed.   
The return value is the File Class object.   
It will returns nil if you have specified the ':STDOUT' to the 'file\_name' parameters of #init.  
In addition, it will returns nil and issues an error message when you call when you have not closed the I/O port of log file.

* <span class="method">flush</span>  
Perform a forced rotation.   
Use this method when you want to rotate the log file that size is less than the 'limit'.   
However, It will returns nil without rotation If you specify what other than file size, like 'DAILY'.  
It will returns nil if you have specified the ':STDOUT' to the 'file\_name' parameters of #init.  


* <span class="method">threshold [= log\_level]</span>  
All log messages have log levels that "DEBUG" to "INFO" to "WORN" to "ERROR" to "FATAL".  
Severity of log messages increase from left to right.   
And to specify here it is whether you want to output log messages to a file at any level or later.  
The log messages other than "ERROR", "FATAL" will not be output to the file.    
Default threshold is 'INFO'.   
It will returns the current value if you do not define a value.  
<div class="param_header">Parameters</div>  
  * <span class="type">String</span> <span class="param">log\_lelvel</span>  
One of the strings "DEBUG", "INFO", "WORN", "ERROR", "FATAL".   
<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log", "DAILY")
logger.threshold = "ERROR"
</p>


* <span class="method">logging\_format [= format]</span>  
<div class="param_header">Parameters</div>  
  * <span class="type">String</span> <span class="param">format</span>  
Specifies the format when outputting the log messages to a file.    
Constant that can be used in the format is as follows.  
<span style ="color: green; font-size: smaller;">  
$DATE  - Date. You can define the date format by #date\_format method.  
$PID   - Process ID of the your script.     
$LEVEL - Level of the log message.  
$LOG   - The log message. It is the argument #w(message).   
$FILE  - File name of Ruby script running Currently (only file name).   
$FILE-FUL  - File name of Ruby script running Currently (absolute path).   
</span>  
Default is "[$DATE] - $LEVEL : $LOG"   
Therefore it will be output as follows.   
<span style="color: blue; background-color: lightyellow;">[2013/10/04 17:42:06] - FATAL : foo</span>   
It will returns the current value if you do not define a value.  
<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log", "1G")
logger.logging\_format = "[$LEVEL] : $DATE => $LEVEL: [$LOG] @ $FILE-FUL"
logger.fatal.w("test")
  <span class="em">It is output to the log file as described below.</span>
<span style="color: yellow;">[FATAL] : 2013/10/23 20:15:13 => FATAL: [test] @ /var/log/ruby/app/foo.log</span>
</p>


* <span class="method">date\_format [= format]</span>  
<div class="param_header">Parameters</div>  
  * <span class="type">String</span> <span class="param">format</span>  
Specifies the format of $DATE constant when outputting log messages to a file.   
Format is the same as the argument of Date#strftime (format).   
Default is "% Y /% m /% d% H: M%:% S", So $DATE will output as '2013/10/04 20:04:59'.    
It will returns the current value if you do not define a value.  
<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log", "DAILY")
logger.date\_format = "%y/%m/%d - %H:%M:%S"
</p>

* <span class="method">rename\_format [= format]</span>  
<div class="param_header">Parameters</div>  
  * <span class="type">String</span> <span class="param">format</span>  
When the log file is rotated, Log files will be renamed as file\_name.20131024 and file\_name.1.   
You can be changed to any string to be specified here part of this dot.    
Default is '.'.   
It will returns the current value if you do not define a value.     
<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log", "1G")
logger.rename\_format = ".foo."
  <span class="em">\# => It will be renamed as file\_name.foo.1</span>
</p>


* <span class="method">no\_wcheck</span>  
Does not check should be rotation in #w method executing.   
Thus rotation of the file is not done by #w method execution.

* <span class="method">file\_closed?</span>  
It will return the bool value: Whether the log file is closed.   
It will returns nil if you have specified the ':STDOUT' to the 'file_name' parameters of #init.

* <span class="method">silence</span>  
It does not output the WARNING message.   
A WARNING message that is output to STDERR when the unexpected situation in SimpleRotate occurs inside.   
Example: [WARNING] File is already open! - (SimpleRotate::Error)  

* <span class="method">debug</span>  
Change to "DEBUG" the log level.      
It will return self so can to connect to #w method by the method chain.  
"DEBUG" is a message for debugging.  

* <span class="method">info</span>  
Change to "INFO" the log level.  
It will return self so can to connect to #w method by the method chain.   
"INFO" is the information on the program.   

* <span class="method">warn</span>  
Change to "WARN" the log level.  
It will return self so can to connect to #w method by the method chain.   
"WARN" is not a serious error but prompts a warning.   

* <span class="method">error</span>  
Change to "ERROR" the log level.  
It will return self so can to connect to #w method by the method chain.   
"ERROR" is a message indicating an error.

* <span class="method">fatal</span>  
Change to "FATAL" the log level.  
It will return self so can to connect to #w method by the method chain.   
"FATAL" is a fatal error message program such that the abort.
<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log")
logger.warn << "log message"
logger << "log message" <span class="em"># It will take over "WORN" log level to be omitted.</span>
logger.fatal << "log message"
logger << "log message" <span class="em"># It will take over "FATAL" log level to be omitted.</span>
<span style="color: yellow;">
[2013/12/16 14:15:03] - WARN : log message
[2013/12/16 14:15:03] - WARN : log message
[2013/12/16 14:15:03] - FATAL : log message
[2013/12/16 14:15:03] - FATAL : log message
</span>
</p>

* <span class="method">sleep\_time [= Integer]</span>   
Specifies the time in seconds to stop after the rotation is completed.    
This is important in a multi-threaded, multi-process.    
There is no advantage to call especially if you run a single.    
In addition, it is also can be specified in the parameter of #psafe_mode method.


* <span class="method">psafe\_mode(sleep\_time=0.1)</span>  
Process safe mode.   
You should call this before #init method, Because there is a critical section in #init.   
Please see the <a href="#multi">About multi thread, multi process</a>.
<div class="param_header">Parameters</div>
  * <span class="type">Integer</span> <span class="param">sleep\_time</span>   
Specifies the time in seconds to stop after the rotation is completed.   
Default is 0.1 seconds.    
Please try to increase this value if more than one process had gone at the same times execute rotation.   
This is because of considering the overhead rename until actually takes place.  

<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.psafe_mode(3)
logger.init("/var/log/ruby/app/foo.log")
</span>
</p>

* <span class="method">sync\_inode</span>  
Compare the inode number of the file specified by file\_name of #init method and inode number of the file that is currently open.    
If there is a difference, The log file will be reopened: In order to write to the latest it.   
It is not a method that to call by user consciously, It will done automatically at #w method is called.   
The case of that has a difference in the inode number, or if can not get the inode number for some reason, will try to reopen three times at most.    
Still inode number does not match It returns false and output the error message.   
After calling #no\_sync\_inode, this method always returns nil without confirmation of the inode number.   
It will returns nil if you have specified the ':STDOUT' to the 'file_name' parameters of #init.   
Will return true otherwise.


* <span class="method">no\_sync\_inode</span>    
Does not Compare the inode number of the file specified by file\_name of #init method and inode number of the file that is currently open.  
You should use a single thread, single process.


<h2 class="header">Class</h2>
### SimpleRotate::Error
> Inner class to handle exceptions in SimpleRotate library.    
> Error that can occur in internal SimpleRotate basically this is the exception. 

### SimpleRotate::ProcessSync
> Inner class for the process safe.    
> Mix-in by SimpleRotate::ProcessSyncMixin.

<h2 class="header">Module</h2>
> Modules to be used in SimpleRotate library.   
### SimpleRotate::LogLevel
### SimpleRotate::RotateTerm
### SimpleRotate::ProcessSyncMixin
### SimpleRotate::Validator


<h2 class="header">Required</h2>
Standard attached libraries that are required by SimpleRotate class.
### singleton
### monitor
### zlib
