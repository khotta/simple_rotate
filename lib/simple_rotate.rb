# SimpleRotate - simple logger for ruby
# @autor: Kazuya Hotta (nyanko)
#
require "singleton"
require "monitor"

class SimpleRotate
  VERSION = "1.0.0"
  include Singleton
  include MonitorMixin

  #----------------
  # modlues
  #----------------
  module LogLevel
    LOG_LEVEL_5    = "FATAL"
    LOG_LEVEL_4    = "ERROR"
    LOG_LEVEL_3    = "WARN"
    LOG_LEVEL_2    = "INFO"
    LOG_LEVEL_1    = "DEBUG"
    LEVEL_ID_FATAL = 5
    LEVEL_ID_ERROR = 4
    LEVEL_ID_WARN  = 3
    LEVEL_ID_INFO  = 2
    LEVEL_ID_DEBUG = 1
  end
  include LogLevel

  module RotateTerm
    TERM_DAILY     = 1
    TERM_WEEKLY    = 7
    TERM_MONTHLY   = 30
  end
  include RotateTerm

  module Validator
    def valid_file_name
      # stdout only
      if @file_name.is_a?(Symbol) && @file_name == :STDOUT
        @only_stdout = true
        return true
      end

      # not string
      if !@file_name.is_a?(String)
        SimpleRotate::Error.argv("file_name", @file_name)
      end

      # directory?
      if File.directory?(@file_name)
        msg = "ERROR => #{@file_name} is a Directory!"
        SimpleRotate::Error.warning(msg)
        SimpleRotate::Error.argv("file_name", @file_name)
      end

      return true
    end

    def valid_int(param, argv)
      if !argv.is_a?(Integer)
        SimpleRotate::Error.argv(param, argv)

      elsif argv < 0
        msg = %{You can't specify the negative value!}
        SimpleRotate::Error.warning(msg)
        SimpleRotate::Error.argv(param, argv)
      end
    end

    def valid_bool(param, argv)
      argv = true  if argv == 1
      argv = false if argv == 0
      if !(argv.instance_of?(TrueClass) || argv.instance_of?(FalseClass))
        SimpleRotate::Error.argv(param, argv)
      end
      return true
    end
  end
  include Validator

  #----------------
  # classes
  #----------------
  #
  # error class for SimpleRotate
  #
  class Error < RuntimeError
    msg  = "aborted the log file rotation process,"
    msg += " because an unexpected error has occured."
    ROTATION_FAILED = msg

    @@silence = false

    #
    # skip warning message
    #
    def self.silence
      @@silence = true
    end

    #
    # argument error
    #
    def self.argv(param, argv)
      msg = "'#{param}'='#{argv}' is invalid argument value!"
      self.throw_error(msg)
    end

    #
    # method missing
    #
    def self.missing(name)
      msg = "undifined method 'SimpleRotate##{name}'"
      self.throw_error(msg)
    end

    #
    # file open error
    #
    def self.open(name)
      msg = "Couldn't open a '#{name}'"
      self.throw_error(msg)
    end

    #
    # load error
    #
    def self.load(name)
      msg = "Couldn't load a '#{name}'"
      self.throw_error(msg)
    end

    #
    # exist error
    #
    def self.exist(name, type)
      msg = "Already exists this #{type} => '#{name}'"
      self.throw_error(msg)
    end

    #
    # warning - don't throw error
    #
    def self.warning(msg)
      warn "[WARNING] #{msg} - (SimpleRotate::Error)" if !@@silence
    end

    # @param msg string
    #
    def self.throw_error(msg)
      exeption = self.new(msg)
      warn exeption.message if !@@silence
      raise SimpleRotate::Error
    end
  end

  #
  # The module for the process safe
  # This module will be included by ProcessSync class
  #
  module ProcessSyncMixin
    @@scheduled_del_lockfile = false
    @@tempf_name             = nil
    @@tempf                  = nil

    def locked?
      return false if !tempf_exists?

      # return false, if locked by another
      status = @@tempf.flock(File::LOCK_EX | File::LOCK_NB)

      return status == false
    end

    # lock the temp file
    def lock
      create_tempfile if !tempf_exists?

      # if don't reopen temp file, can't lock...
      reopen_temp_file

      cnt = 0
      begin
        @@tempf.flock(File::LOCK_EX)

      rescue
        cnt += 1
        if (cnt <= @try_limit)
          sleep(0.5)
          create_tempfile if !tempf_exists?
          retry
        else
          SimpleRotate::Error.warning("It was not possible to lock (tried 3times) => #{@@tempf_name}")
          return false
        end
      end
    end

    # unlock the temp file
    def unlock
      return nil if !tempf_exists?

      begin
        @@tempf.flock(File::LOCK_UN)
      rescue
        SimpleRotate::Error.warning("It was not possible to unlock => #{@@tempf_name}")
      end
    end
  end

  #
  # The classes for process-safe
  #
  class ProcessSync
    include ProcessSyncMixin

    ProcessSyncMixin.instance_methods.each do |method_name|
      method = instance_method(method_name)
      define_method(method_name) do |*args|
        ###################
        # common execution
        ###################
        # Processing to be performed at the beginning of the method
        return nil if !@enable
        ###################
        method.bind(self).call(*args)
      end
    end

    def initialize(sr)
      @sr          = sr
      @enable      = sr.instance_variable_get(:@psafe_mode)
      @file_name   = sr.instance_variable_get(:@file_name)

      # #init not called
      return self if @file_name == nil

      @logf        = sr.instance_variable_get(:@logf)
      @try_limit   = 3
      @@tempf_name = File.dirname(@file_name) + File::SEPARATOR + ".SimpleRotate_tempfile_#{File.basename($0)}"

      create_tempfile if @enable && !@@scheduled_del_lockfile
    end

    # Create the temp file for locking
    private
    def create_tempfile
      if File.exist?(@@tempf_name)
        open_temp_file
        return nil
      end

      begin
        @@tempf = File.open(@@tempf_name, File::RDWR|File::CREAT|File::EXCL)

      rescue
        SimpleRotate::Error.warning("Couldn't create temp file => #{@@tempf_name}")

      ensure
        set_delete_tempfile
      end
    end

    private
    def tempf_exists?
      return File.exist?(@@tempf_name)
    end

    # Delete the lock file at the end of the script
    private
    def set_delete_tempfile
      return true if @@scheduled_del_lockfile

      if File.exists?(@@tempf_name)
        # is it empty?
        if File.size(@@tempf_name) == 0
          delete_at_end
        else
          # it is not empty
          msg  = "File is not empty => #{@@tempf_name}#{$-0}"
          msg += "Skip to delete temp file!"
          SimpleRotate::Error.warning(msg)
        end
      end
      @@scheduled_del_lockfile = true
    end

    private
    def delete_at_end
      at_exit do
        begin
          File.delete(@@tempf_name)
        rescue
          #SimpleRotate::Error.warning("Couldn't delete temp file => #{@@tempf_name}")
        end
      end
    end

    private
    def reopen_temp_file
      close_temp_file
      open_temp_file
    end

    private
    def open_temp_file
      if @@tempf.is_a?(IO) && @@tempf.closed? || !@@tempf.is_a?(IO)
        begin
          @@tempf = File.open(@@tempf_name, File::RDWR|File::CREAT|File::APPEND)
        rescue
          SimpleRotate::Error.warning("Couldn't open temp file => #{@@tempf_name}")
        end
      end
    end

    private
    def close_temp_file
      if @@tempf.is_a?(IO) && !@@tempf.closed?
        begin
          @@tempf.close
        rescue
          SimpleRotate::Error.warning("Couldn't close temp file => #{@@tempf_name}")
        end
      end
    end
  end

  #--------------------
  # access definitions
  #--------------------
  attr_accessor :threshold,
                :date_format,
                :logging_format,
                :rename_format,
                :allow_overwrite,
                :sleep_time

  attr_reader   :limit

  #----------------
  # public methods
  #----------------
  #
  # return method missing error
  #
  def method_missing(name, *argv)
    SimpleRotate::Error.missing(name)
  end

  #
  # @param string|symbol $file_name
  # @param string|int    $limit
  # @param int           $rotation
  # @return self
  #
  def init(file_name=File.absolute_path($0+".log"), limit='1M', rotation=0) 
    @file_name = file_name
    @limit     = limit
    @rotation  = rotation

    # load defaults
    include_defaults

    # validation
    valid_file_name
    valid_int("rotation", @rotation)

    # stdout only
    return self if @only_stdout

    if rotate_by_term?
      # term rotation
      set_days_cnt_of_term
      @limit_term     = @limit
      @rotate_by_term = true

    else  
      # file_size rotation
      @limit_size = trim_byte(@limit)
      if @limit_size <= 0
        SimpleRotate::Error.argv("limit", @limit)
      end
      @rotate_by_term = false
    end

    # for process safe
    @psync = ProcessSync.new(self)

    # open or generate the log file
    synchronize do
      @psync.lock

      prepare_logf

      @psync.unlock
    end

    # if block given, colse IO
    if defined? yield
      yield self
      e
    end

    return self
  end

  #
  # log message out to STDOUT when use SimpleRotate#w method
  #
  def with_stdout
    @with_stdout = true
  end

  #
  # enable compress
  #
  def compress
    @compress = true
    use_zlib
  end

  #
  # define the compression level
  # this method load 'zlib'
  # this method enable compress flag
  # @param int level - 0-9
  #                    default is 6
  # 
  def compress_level(level)
    @compress_level = level
    valid_int("compress_level", @compress_level)
    compress

    return level
  end

  #
  # @param  string $log message write to log file
  # @return string
  #
  def w(log)
    if @file_name == nil
      msg = "file_name is Nil Class! Please call #init method"
      SimpleRotate::Error.throw_error(msg)
    end

    # don't out log message if Doesn't reach threshold
    return nil if (!over_threshold?)

    content = get_trimmed_log(log)

    # return and end func, if only_stdout enable
    if @only_stdout
      puts content
      return log
    end

    # write message to file
    synchronize do
      @psync.lock

      sync_inode
      @logf.puts(content)
      @logf.flush if @enable_wflush
      @logf.fsync if @enable_wflush

      @psync.unlock
    end

    # dump log message STDOUT, if with_stdout enable
    puts content if @with_stdout

    # rotate if necessary
    rotate_if if !@no_wcheck

    return log
  end

  #
  # disable call File#flush after #w method
  #
  def enable_wflush
    @enable_wflush = true
  end

  #
  # enable call File#flush after #w method
  #
  def disable_wflush
    @enable_wflush = false
  end

  #
  # close file
  #
  def e
    return nil if logf_not_usable

    synchronize do
      @psync.lock

      @logf.close

      @psync.unlock
    end
  end

  #
  # file reopen
  #
  def reopen
    return nil if logf_not_usable

    if !file_closed?
      SimpleRotate::Error.warning("File is already open!")
      return nil
    end

    openadd
    return @logf
  end

  #
  # force rotation
  #
  def flush
    return nil if logf_not_usable
    return nil if @rotate_by_term
    rotation(:FLUSH)
  end

  #
  # don't check can to rotate at #w method
  #
  def no_wcheck
    @no_wcheck = true
  end

  #
  # is log file open?
  # @return nil|bool
  #
  def file_closed?
    return nil if logf_not_usable
    return @logf.closed?
  end

  #
  # skip warning message
  #
  def silence
    SimpleRotate::Error.silence
  end

  #
  # set log level FATAL
  # @return self
  #
  def fatal
    @log_level = 5
    return self
  end

  #
  # set log level ERROR
  # @return self
  #
  def error
    @log_level = 4
    return self
  end

  #
  # set log level WORN
  # @return self
  #
  def warn
    @log_level = 3
    return self
  end

  #
  # set log level INFO
  # @return self
  #
  def info
    @log_level = 2
    return self
  end

  #
  # set log level DEBUG
  # @return self
  #
  def debug
    @log_level = 1
    return self
  end

  #
  # try to be a safe process
  #
  def psafe_mode(sleep_time=0.1)
    @psafe_mode    = true
    @enable_wflush = true
    @sleep_time    = sleep_time

    @psync = ProcessSync.new(self)
  end

  #
  # Reopen file necessary
  # @return bool|nil
  #
  def sync_inode
    return nil if logf_not_usable

    cnt = 0
    begin
      # check i-node number
      open_inode = @logf.stat.ino
      logf_inode = File.stat(@file_name).ino
      raise if open_inode != logf_inode
    rescue
      cnt += 1
      sleep(0.1)
      e
      openadd

      if cnt <= @sync_inode_limit
        retry
      else
        SimpleRotate::Error.warning(%{inode number didn't not match, tried #{cnt} times!})
        return false
      end
    end

    return true
  end

  #
  # Disable #sync_inode
  #
  def no_sync_inode
    @no_sync_inode = true
  end

  #----------------
  # private methods
  #----------------
  #
  # log file is not IO class or stdout only
  # @return bool
  #
  private
  def logf_not_usable
    !@logf.is_a?(IO) || @only_stdout
  end

  #
  # load zlib lib
  #
  private
  def use_zlib
    begin
      require "zlib"
      @compress_level = Zlib::DEFAULT_COMPRESSION if @compress_level == nil

    rescue LoadError
      SimpleRotate::Error.load("zlib")
    end
  end

  #
  # open or generate the log file
  #
  private
  def prepare_logf
    if File.exist?(@file_name)
      # open the exists file, add mode
      openadd

      # rotate it if necessary
      rotate_if

    else
      gen_new_logf
    end
  end

  #
  # generate new log file
  #
  private
  def gen_new_logf
    begin
      @logf = File.open(@file_name, File::RDWR|File::CREAT|File::TRUNC)
      gtime = Time.new.to_i
      @logf.puts("created@#{gtime}@Please don't delete this line")
      @logf.close

    rescue
      SimpleRotate::Error.open(@file_name)
    end

    openadd
  end

  #
  # if file or directory exist, call error
  #
  private
  def exist_error(file)
    SimpleRotate::Error.exist(file, "File")      if File.exist?(file)
    SimpleRotate::Error.exist(file, "Directory") if Dir.exist?(file)

    return true
  end

  #
  # define default instance vars
  #
  private
  def include_defaults
    que = []
    que << [%{@threshold},        %{LOG_LEVEL_2}]
    que << [%{@log_level},        %{2}]
    que << [%{@logging_format},   %{"[$DATE] - $LEVEL : $LOG"}]
    que << [%{@date_format},      %{"%Y/%m/%d %H:%M:%S"}]
    que << [%{@term_format},      %{"%Y%m%d"}]
    que << [%{@rename_format},    %{"."}]
    que << [%{@with_stdout},      %{false}]
    que << [%{@only_stdout},      %{false}]
    que << [%{@no_wcheck},        %{false}]
    que << [%{@sync_inode_limit}, %{3}]
    que << [%{@no_sync_inode},    %{false}]
    que << [%{@enable_wflush},    %{false}]
    que << [%{@compress},         %{false}]
    que << [%{@psafe_mode},       %{false}]
    que << [%{@sleep_time},       %{0}]

    que.each do |q|
      if eval(%{#{q[0]} == nil})
        eval(%{#{q[0]} = #{q[1]}})
      end
    end
  end

  #
  # Whether to rotate by file age?
  # @return bool 
  #
  private
  def rotate_by_term?
    if @limit.is_a?(Integer)
      return false

    elsif @limit.is_a?(String)
      return @limit.to_i == 0

    else
      SimpleRotate::Error.argv("limit", @limit)
    end
  end

  #
  # Open the log file, add mode
  #
  private
  def openadd
    @logf = File.open(@file_name, File::RDWR|File::CREAT|File::APPEND)

    # refresh object
    @psync = ProcessSync.new(self)
  end

  #
  # get cretated time of the log file
  # @return Time
  #
  private
  def get_logf_generate_time
    pos = @logf.pos
    begin
      @logf.rewind
      stamp = @logf.readline.split("@")
      @logf.seek(pos)
      gtime = Time.at(stamp[1].to_i)

    rescue StandardError, SyntaxError
      msg   = "Can't get file creation time!"
      gtime = Time.now
      SimpleRotate::Error.warning(msg)
    end

    return gtime
  end

  #
  # @return int
  #
  private
  def  set_days_cnt_of_term
    begin
      @dayc = eval("TERM_#{@limit}")
    rescue NameError
      SimpleRotate::Error.argv("limit", @limit)
    end
  end

  #
  # log file size over 'limit_size'? 
  # @return bool|nil
  #
  private
  def over_size?
    return nil if logf_not_usable

    begin
      rst =  File.size(@file_name) > @limit_size
    rescue
      rst = false
    end

    return rst
  end

  private
  def safe_over_size?
    rst = nil
    synchronize do
      @psync.lock
      rst = over_size?
      @psync.unlock
    end

    return rst
  end

  #
  # logfile's elapsed days is over limit?
  # @return bool
  #
  private
  def over_term?
    return nil if logf_not_usable

    begin
      now_time       = Time.now
      gen_time       = get_logf_generate_time
      estimated_time = gen_time + (60 * 60 * 24 * @dayc)
      rst            =  estimated_time <=  now_time
    rescue
      rst = false
    end

    return rst
  end

  private
  def safe_over_term?
    rst = nil
    synchronize do
      @psync.lock
      rst = over_term?
      @psync.unlock
    end

    return rst
  end

  #
  # Format the text for logging
  # the following characters are recognized 
  # $DATE  => date
  # $LEVEL => log's severity
  # $LOG   => your log message
  # $PID   => process ID
  # $FILE  => execute file name
  #
  # @param  string $log
  # @return string
  #
  private
  def get_trimmed_log(log)
    log   = log.to_s
    date  = Time.now.strftime(@date_format)
    level = eval("LOG_LEVEL_#{@log_level}")
    return @logging_format.gsub("$DATE", date)
                          .gsub("$LEVEL", level)
                          .gsub("$LOG", log)
                          .gsub("$PID", $$.to_s)
                          .gsub("$FILE-FUL", File.absolute_path($0))
                          .gsub("$FILE", File.basename($0))
  end

  #
  # Whether that is the output of the log level that exceeds the threshold 
  # @return boolean
  #
  private
  def over_threshold?
    begin
      return (@log_level >= eval("LEVEL_ID_#{@threshold}"))
    rescue NameError
      SimpleRotate::Error.argv("threshold", @threshold)
    end
  end

  #
  # need rotate?
  # @return bool
  #
  private
  def reached_limit?(mode=:NO_LOCK)
    # file age rotation
    if @rotate_by_term
      is_over_term  = nil
      if mode == :NO_LOCK
        is_over_term = over_term?
      elsif mode == :LOCK
        is_over_term = safe_over_term?
      end

      return is_over_term
    end

    # file size rotation
    is_over_size = nil
    if mode == :NO_LOCK
      is_over_size = over_size?
    elsif mode == :LOCK
      is_over_size = safe_over_size?
    end

    return is_over_size
  end

  #
  # Rotates as necessary
  # @return bool
  #
  private
  def rotate_if
    if reached_limit?(:LOCK)
      rotation
      return true

    else
      # no need to rotate
      return false
    end
  end

  #
  # prepare & call #do_rotation
  #
  private
  def rotation(mode=:NO_SPEC)
    synchronize do
      # if rotationing now by another process, return
      if @psync.locked? #=> if not process safe mode, will be return nil
        return false
      end

      # lock another process if enable
      @psync.lock

      do_rotate(mode)

      # unlock another process if enable
      @psync.unlock
    end
  end

  #
  # Rotate the log file now, and open a new one
  #
  private
  def do_rotate(mode)
    return nil if logf_not_usable

    # check already executed rotation?
    if mode != :FLUSH && !reached_limit?
      return false 
    end

    # file age rotation
    if @rotate_by_term
      rtn = do_term_rotate
      return rtn
    end

    # file size rotation
    cnt         = 1
    rotate_name = "#{@file_name}#{@rename_format}#{cnt}"
    rotate_name += ".gz" if @compress

    if File.exist?(rotate_name)
      while File.exist?(rotate_name)
        cnt        += 1
        rotate_name = "#{@file_name}#{@rename_format}#{cnt}"
        rotate_name += ".gz" if @compress
      end

      rename_wait_que = Array.new
      for nc in 1...cnt
        break if @rotation == 1
        if (@compress)
          rename_wait_que << "File.rename('#{@file_name}#{@rename_format}#{nc}.gz', '#{@file_name}#{@rename_format}#{nc+1}.gz')"
        else
          rename_wait_que << "File.rename('#{@file_name}#{@rename_format}#{nc}', '#{@file_name}#{@rename_format}#{nc+1}')"
        end

        if @rotation
          next  if @rotation == 0
          break if @rotation <= nc+1
        end
      end

      rename_wait_que.reverse!

      begin
        rename_wait_que.each do |do_rename|
          eval(do_rename)
        end
      rescue
        SimpleRotate::Error.warning(SimpleRotate::Error::ROTATION_FAILED)
        return false
      end
    end

    most_recent_name = "#{@file_name}#{@rename_format}1"
    post_execute_rotate(most_recent_name)
  end

  #
  # Rotate the log file now, and open a new one
  # for rotate by term
  #
  private
  def do_term_rotate
    date        = Time.now.strftime(@term_format)
    rotate_name = "#{@file_name}#{@rename_format}#{date}"

    # Don't rotation If a file with the same name already exists
    return false if File.exists?(rotate_name)
    return false if File.exists?("#{rotate_name}.gz")

    post_execute_rotate(rotate_name)
  end

  #
  # rename log_file & generate new one
  #
  private
  def post_execute_rotate(after_name)
    begin
      @logf.close
      File.rename(@file_name, after_name)
      do_compress(after_name) if @compress
      prepare_logf

      # sleep after rotation
      sleep(@sleep_time) if @sleep_time > 0

    rescue
      SimpleRotate::Error.warning(SimpleRotate::Error::ROTATION_FAILED)
      reopen if file_closed?
    end
  end

  #
  # compress rotated file
  #
  private
  def do_compress(file)
    contents = nil
    File.open(file, File::RDONLY) do |f|
      contents = f.read
    end

    newf = "#{file}.gz"

    io = File.open(newf, File::WRONLY|File::CREAT|File::TRUNC)
    Zlib::GzipWriter.wrap(io, @compress_level) do |writer|
      writer.mtime     = File.mtime(file).to_i
      writer.orig_name = file
      writer.write(contents)
    end

    File.delete(file)
  end

  #
  # convert 'limit_size' to integer
  # @param  string|int $limit_size
  # @return int
  #
  private
  def trim_byte(limit)
    return limit if limit.is_a?(Integer)

    kiro = "000"
    mega = kiro + "000"
    giga = mega + "000"
    tera = giga + "000"
    limit_size = limit

    if /K$/ =~ limit_size
      limit_size = limit_size.sub(/K$/, "") + kiro
    elsif  /M$/ =~ limit_size
      limit_size = limit_size.sub(/M$/, "") + mega
    elsif  /G$/ =~ limit_size
      limit_size = limit_size.sub(/G$/, "") + giga
    elsif  /T$/ =~ limit_size
      limit_size = limit_size.sub(/T$/, "") + tera
    end

    return limit_size.to_i
  end

  #--------------------
  # method alias
  #--------------------
  alias_method :<<, :w
end
