#----------------
# private methods
#----------------
class SimpleRotate
    # log file is not IO class or stdout only
    # @return bool
    private
    def logf_not_usable
        !@logf.is_a?(IO) || @only_stdout
    end

    # load zlib lib
    private
    def use_zlib
        begin
            require "zlib"
            @compress_level = Zlib::DEFAULT_COMPRESSION if @compress_level == nil

        rescue LoadError
            SimpleRotate::Error.load("zlib")
        end
    end

    # open or generate the log file
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

    # generate new log file
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

    # if file or directory exist, call error
    private
    def exist_error(file)
        SimpleRotate::Error.exist(file, "File")      if File.exist?(file)
        SimpleRotate::Error.exist(file, "Directory") if Dir.exist?(file)

        return true
    end

  # define default instance vars
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
        que << [%{@is_psync},         %{false}]
        que << [%{@sleep_time},       %{0}]

        que.each do |q|
            if !eval(%{self.instance_variable_defined? :#{q[0]}})
                eval(%{#{q[0]} = #{q[1]}})
            end
        end
    end

    # Whether to rotate by file age?
    # @return bool 
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

    # Open the log file, add mode
    private
    def openadd
        @logf = File.open(@file_name, File::RDWR|File::CREAT|File::APPEND)

        # refresh object
        @psync = ProcessSync.new(self)
    end

    # get cretated time of the log file
    # @return Time
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

    # @return int
    private
    def set_days_cnt_of_term
      begin
          @dayc = eval("TERM_#{@limit}")

      rescue NameError
          SimpleRotate::Error.argv("limit", @limit)
      end
    end

    # log file size over 'limit_size'? 
    # @return bool|nil
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

    # logfile's elapsed days is over limit?
    # @return bool
    private
    def over_term?
        return nil if logf_not_usable

        begin
            now_time       = Time.now
            gen_time       = get_logf_generate_time
            estimated_time = gen_time + (60 * 60 * 24 * @dayc)
            rst            = estimated_time <=  now_time

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
    private
    def get_trimmed_log(log)
        if log == nil
            log = log.inspect
        else
            log = log.to_s
        end

        date  = Time.now.strftime(@date_format)
        level = eval("LOG_LEVEL_#{@log_level}")
        return @logging_format.gsub("$DATE", date)
                              .gsub("$LEVEL", level)
                              .gsub("$LOG", log)
                              .gsub("$PID", $$.to_s)
                              .gsub("$FILE-FUL", File.absolute_path($0))
                              .gsub("$FILE", File.basename($0))
    end

    # Whether that is the output of the log level that exceeds the threshold 
    # @return boolean
    private
    def over_threshold?
        begin
            return (@log_level >= eval("LEVEL_ID_#{@threshold}"))

        rescue NameError
            SimpleRotate::Error.argv("threshold", @threshold)
        end
    end

    # need rotate?
    # @return bool
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

    # Rotates as necessary
    # @return bool
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

    # prepare & call #do_rotation
    private
    def rotation(mode=:NO_SPEC)
        synchronize do
            # if rotationing now by another process, return
            if @psync.locked? #=> when didn't call #psync, will be return nil
                return false
            end

            # lock another process if enable
            @psync.lock

            do_rotate(mode)

            # unlock another process if enable
            @psync.unlock
        end
    end

    # rotate the log file and open a new one
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

    # Rotate the log file now, and open a new one
    # for rotate by term
    private
    def do_term_rotate
        date        = Time.now.strftime(@term_format)
        rotate_name = "#{@file_name}#{@rename_format}#{date}"

        # Don't rotation If a file with the same name already exists
        return false if File.exists?(rotate_name)
        return false if File.exists?("#{rotate_name}.gz")

        post_execute_rotate(rotate_name)
    end

    # rename log_file & generate new one
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

    # compress rotated file
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

    # convert 'limit_size' to integer
    # @param  string|int $limit_size
    # @return int
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
end
