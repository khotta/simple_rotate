# coding: utf-8

# load standard attachments
require "singleton"
require "monitor"

# load internal modules
require_relative "./internal/log_level"
require_relative "./internal/rotate_term"
require_relative "./internal/validator"
require_relative "./internal/error"

# load internal classes
require_relative "./internal/error"
require_relative "./internal/process_sync"

# extends myself
require_relative "./const"
require_relative "./accesser"
require_relative "./private"

class SimpleRotate
    # mix-in
    include Singleton
    include MonitorMixin
    include LogLevel
    include RotateTerm
    include Validator

    # return method missing error
    def method_missing(name, *argv)
        SimpleRotate::Error.missing(name)
    end

    # @param string|symbol $file_name
    # @param string|int    $limit
    # @param int           $rotation
    # @return self
    def init(file_name=File.absolute_path($0+".log"), limit="100M", rotation=0) 
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

        # for process sync
        @psync = ProcessSync.new(self)

        # open or generate the log file
        synchronize do
            @psync.lock

            prepare_logf

            @psync.unlock
        end

        # if block is given, colse IO
        if defined? yield
            yield self
            e
        end

        return self
    end

    # log message out to STDOUT when use SimpleRotate#w method
    def with_stdout
        @with_stdout = true
        return nil
    end

    # enable compress
    def compress
        @compress = true
        use_zlib
        return nil
    end

    # define the compression level
    # this method load 'zlib'
    # this method enable compress flag
    # @param int level - 0-9
    #                    default is 6
    def compress_level(level)
        @compress_level = level
        valid_int("compress_level", @compress_level)
        compress
        return nil
    end

    # @param  string $log message write to log file
    # @return string
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

            sync_inode if !@no_sync_inode
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

    # disable call File#flush after #w method
    def enable_wflush
        @enable_wflush = true
        return nil
    end

    # enable call File#flush after #w method
    def disable_wflush
        @enable_wflush = false
        return nil
    end

    # close file
    def e
        return nil if logf_not_usable

        synchronize do
            @psync.lock

            @logf.close

            @psync.unlock
        end

        return true
    end

    # file reopen
    def reopen
      return nil if logf_not_usable

      if !file_closed?
          SimpleRotate::Error.warning("File is already open!")
          return nil
      end

      openadd
      return @logf
    end

    # force rotation
    def flush
        return nil if logf_not_usable
        return nil if @rotate_by_term
        rotation(:FLUSH)
        return true
    end

    # don't check can to rotate at #w method
    def no_wcheck
        @no_wcheck = true
        return nil;
    end

    # is log file open?
    # @return nil|bool
    def file_closed?
        return nil if logf_not_usable
        return @logf.closed?
    end

    # skip warning message
    def silence
        SimpleRotate::Error.silence
        return nil;
    end

    # set log level FATAL
    # @return self
    def fatal
        @log_level = 5
        return self
    end

    # set log level ERROR
    # @return self
    def error
        @log_level = 4
        return self
    end

    # set log level WORN
    # @return self
    def warn
        @log_level = 3
        return self
    end

    # set log level INFO
    # @return self
    def info
        @log_level = 2
        return self
    end

    # set log level DEBUG
    # @return self
    def debug
        @log_level = 1
        return self
    end

    # synchronize processes
    def psync(sleep_time=0.1)
        @is_psync      = true
        @enable_wflush = true
        @sleep_time    = sleep_time

        @psync = ProcessSync.new(self)
        return nil
    end

    # reopen file necessary
    # @return bool|nil
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

    # disable #sync_inode
    def no_sync_inode
        @no_sync_inode = true
        return nil
    end

    #--------------------
    # method alias
    #--------------------
    alias_method :<<, :w
end
