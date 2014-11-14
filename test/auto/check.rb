#!/usr/local/rbenv_data/shims/ruby
require "rubygems"
#require "simple_rotate"
require "~/simple_rotate/trunk/lib/simple_rotate"
require "pp"
require 'minitest/unit'
require "mathn"
require "parallel"

module Debuger
end

class Test
  def dump
    puts "at Test class context"
    @logger = SimpleRotate.instance
    p @logger
    @logger.w "Writed at Test class context"
  end
end

class TestSimpleRotate < MiniTest::Unit::TestCase
  def setup
    @logger = SimpleRotate.instance
  end

  def teardown
    print "\e[0m"
  end

  def dump_var(var)
    val = @logger.instance_variable_get(var)
    header = "#{var}: "
    rst(val, header)
  end

  def dump_file(file)
    @logger.e if !@logger.file_closed?

    f = File.open(file)
    puts "------------------------------- #{file} -------------------------------"
    puts f.read
    puts "-----------------------------------------------------------------------------"
    f.close
    @logger.reopen
  end

  def exe(pgm)
    func pgm
    eval pgm
  end

  def tip(msg)
    print "\e[32m"
    puts "* #{msg}"
    print "\e[0m"
  end

  def info(msg)
    print "\e[7m"
    print "\e[34m"
    print "[INFO]"
    print "\e[0m"
    puts " #{msg}"
  end

  def func(msg)
    print "\e[7m"
    print "\n[PROGRAM]"
    print "\e[0m"
    puts " #{msg}"
    print $-0
  end

  def rst(msg, header=" ")
    print "\e[7m"
    print "\e[36m"
    print "[RESULT]"
    print "\e[0m"
    print header
    print "\e[34m"
    p msg
    print "\e[0m"
    print $-0
  end

  def cmm(msg)
    print "\e[4m"
    print "\e[5m"
    print "\e[7m"
    print "\e[31m"
    print "\n[PLEASE DO]"
    print "\e[0m"
    print "\e[4m"
    puts " #{msg}"
    print "\e[0m"
  end

  def fsize(file)
    size = File.size(file)/1000
    size = size.to_f
    info("#{file} size is : #{size}KB")
  end

  def write_to(file, roop=1)
    tip "limit is => #{@logger.limit}"
    tip "roop is => #{roop}"
    fsize(file)

    rd       = Random.rand(0...10)
    contents = "#{rd}" * 100

    info "@logger.w #{roop} roop!"
    File.open(file, "a+") do |f|
      for i in 0...roop
        @logger.w contents
      end
    end

    fsize(file)
    puts ""
  end

  def w_all_mode(file)
    @logger.debug.w("debug")
    @logger.info.w("info")
    @logger.warn.w("warn")
    @logger.error.w("error")
    @logger.fatal.w("fatal")
    info "writed all threshold!"
    dump_file(file) 
  end

  def test_wall
    pgm = %{@logger.init()}
    exe pgm
    @logger.debug.w("debug")
    @logger.info.w("info")
    @logger.warn.w("warn")
    @logger.error.w("error")
    @logger.fatal.w("fatal")
    info "writed all threshold!"
  end

  def go_back_logs_date(file, term=1)
    now    = Time.now
    sec    = (60 * 60 * 24) * term
    rewind = now - sec
    str    = rewind.strftime("%Y/%m/%d %H:%M:%S")
    stamp  = rewind.to_i
    info "#{term} days before's(#{str}) timestamp => #{stamp}"

    if ARGV[0] == "check" || ARGV[0] == "CHECK"
      tip "Write only"
      return
    end

    # replace header time
    diff_min = 3
    diff_sec = 60 * diff_min
    rewind   = rewind + diff_sec
    str      = rewind.strftime("%Y/%m/%d %H:%M:%S")
    stamp    = rewind.to_i
    header   = "created@#{stamp}@Please don't delete this line"

    File.open(file, "r+") do |io|
      info "Original: #{io.readline}"
      io.rewind
      io.puts header
    end
    info "Header's created time has been overwritten => #{str} : #{stamp}"
    info "The log file will be rotated at #{diff_min} minutes after... #{now + diff_sec}"
    cmm "ruby #{$0} -n test_init_limit_N check"
  end

  def test_instance_1
    file = "instance.log"
    pgm = %{@logger.init("#{file}", "1G", 0)}
    exe pgm

    pgm = %{@logger.logging_format="$LOG($LEVEL) [$DATE] @$FILE"}
    exe pgm

    pgm = %{@logger.w "aaa"}
    exe pgm
    dump_file file

    pgm = %{Test.new.dump}
    exe pgm
    dump_file file
  end

  def test_init_file_name_1
    pgm = %{rst @logger.init()}
    exe pgm

    file = "#{$0}.log"

    pgm = %{@logger.w "write 1"}
    exe pgm
    dump_file file

    pgm = %{@logger.w "write 2"}
    exe pgm
    dump_file file
  end

  def test_init_file_name_2
    file = "file_name.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.w "write 1"}
    exe pgm
    dump_file(file)

    pgm = %{@logger.w "write 2"}
    exe pgm
    dump_file(file)
  end

  def test_init_file_name_3
    file = "/home/nyanko/logs/file_name.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.w "write 1"}
    exe pgm
    dump_file(file)

    pgm = %{@logger.w "write 2"}
    exe pgm
    dump_file(file)
  end

  def test_init_file_name_4
    pgm =  %{rst @logger.init(:STDOUT)}
    exe pgm

    pgm = %{@logger.w("file name => :STDOUT")}
    exe pgm

    pgm = %{@logger.w("testtest")}
    exe pgm
  end

  def test_init_file_name_error_1
    pgm = %{@logger.init("/root/file_name.log")}
    exe pgm
  end

  def test_init_file_name_error_2
    pgm = %{@logger.init(:test)}
    exe pgm
  end

  def test_init_file_name_error_3
    pgm = %{@logger.init("/home/nyanko/logs")}
    exe pgm
  end

  def test_init_file_name_error_4
    pgm = %{@logger.init(-9999)}
    exe pgm
  end

  def test_init_limit_1
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm
    write_to(file, 4000)
  end

  def test_init_limit_2
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", 1000000)}
    exe pgm
    write_to(file, 4000)
  end

  def test_init_limit_3
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", "15M")}
    exe pgm
    write_to(file, 90000)
  end

  def test_init_limit_4
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", "5K")}
    exe pgm
    write_to(file, 20)
  end

  def test_init_limit_5
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", "1G")}
    exe pgm
    write_to(file, 5000000)
  end
  
  def test_init_limit_6
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", "100B")}
    exe pgm
    write_to(file, 1)
  end

  def test_init_limit_7
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", 100)}
    exe pgm
    write_to(file, 1)
  end

  def test_init_limit_8
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", "DAILY")}
    exe pgm

    pgm = %{@logger.w "daily"}
    exe pgm
    dump_file file

    go_back_logs_date file
  end

  def test_init_limit_9
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", "WEEKLY")}
    exe pgm

    pgm = %{@logger.w "weekly"}
    exe pgm
    dump_file file

    go_back_logs_date(file, 7)
  end

  def test_init_limit_10
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", "MONTHLY")}
    exe pgm

    pgm = %{@logger.w "monthly"}
    exe pgm
    dump_file file

    go_back_logs_date(file, 30)
  end

  def test_init_limit_11
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", "DAILY")}
    exe pgm

    write_to(file, 4000)
  end

  def test_init_limit_12
    file = "/home/nyanko/logs/init_limit.log"
    pgm = %{@logger.init("#{file}", "100K")}
    exe pgm

    write_to(file, 300)

    pgm = "ls -ltrh ~/logs"
    func pgm
    eval "puts `#{pgm}`"
  end

  def test_init_limit_error_1
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", "MONTHLLY")}
    exe pgm
  end

  def test_init_limit_error_2
    file = "init_limit.log"
    pgm = %{@logger.init("#{file}", -100)}
    exe pgm
    write_to(file, 300)
  end

  def test_init_rotation_1
    file = "rotation.log"
    pgm = %{@logger.init("#{file}", "5K", 0)}
    exe pgm
    write_to(file, 20)
  end

  def test_init_rotation_2
    file = "rotation.log"
    pgm = %{@logger.init("#{file}", "5K", 1)}
    exe pgm
    write_to(file, 20)
  end

  def test_init_rotation_3
    file = "rotation.log"
    pgm = %{@logger.init("#{file}", "5K", 3)}
    exe pgm
    write_to(file, 20)
  end

  def test_init_rotation_4
    file = "rotation.log"
    pgm = %{@logger.init("#{file}", "5K", 10)}
    exe pgm
    write_to(file, 20)
  end

  def test_init_rotation_error_1
    file = "rotation.log"
    pgm = %{@logger.init("#{file}", "5K", -3)}
    exe pgm
    write_to(file, 20)
  end

  def test_init_rotation_error_2
    file = "rotation.log"
    pgm = %{@logger.init("#{file}", "5K", "test")}
    exe pgm
    write_to(file, 20)
  end

  def test_init_block_1
    file = "block.log"

    tip "block start"
    @logger.init(file) do |obj|
      pgm = %{rst @logger.file_closed?}
      exe pgm

      pgm = %{obj.w "test"}
      func pgm
      eval pgm

      pgm = %{obj.w "foo"}
      func pgm
      eval pgm

      pgm = %{obj.w "bar"}
      func pgm
      eval pgm
    end
    tip "block end"

    pgm = %{rst @logger.file_closed?}
    exe pgm

    dump_file file
  end

  def test_init_block_2
    file = "block.log"

    func %{@logger.init(file, "5K")}
    tip "block start"
    @logger.init(file, "5K") do |obj|
      for i in 20.times
        obj.w "9"*100
      end
      info "Writed"
    end
    tip "block end"
  end

  def test_with_stdout_1
    file = "with_stdout.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.w "aaa"}
    exe pgm

    pgm = %{@logger.with_stdout}
    exe pgm

    pgm = %{@logger.w "bbb"}
    exe pgm
    pgm = %{@logger.w "ccc"}
    exe pgm

    dump_file(file)
  end

  def test_compress_1
    file = "compress.log"
    dump_var "@compress_level"
    dump_var "@compress"

    pgm = %{@logger.compress}
    exe pgm

    dump_var "@compress_level"
    dump_var "@compress"

    pgm = %{@logger.init("#{file}", "5K")}
    exe pgm

    dump_var "@compress_level"
    dump_var "@compress"

    write_to(file, 20)
  end

  def test_compress_2
    pgm = %{@logger.compress}
    exe pgm

    file = "compress.log"
    pgm = %{@logger.init("#{file}", "5K", 3)}
    exe pgm

    write_to(file, 20)
  end

  def test_compress_3
    pgm = %{@logger.compress}
    exe pgm

    file = "compress.log"
    pgm = %{@logger.init("#{file}", "1G", 3)}
    exe pgm

    write_to(file, 100)

    pgm = %{@logger.flush}
    exe pgm

    write_to(file, 100)
  end

  def test_compress_4
    pgm = %{@logger.compress}
    exe pgm

    file = "compress.log"
    pgm = %{@logger.init("#{file}", "DAILY")}
    exe pgm

    pgm = %{@logger.w "daily"}
    exe pgm
    dump_file file

    go_back_logs_date file
  end

  def test_compress_level_1
    dump_var "@compress"
    dump_var "@compress_level"

    pgm = "@logger.compress_level(9)"
    exe pgm

    dump_var "@compress"
    dump_var "@compress_level"

    file = "compress_level.log"
    pgm = %{@logger.init("#{file}", "5K")}
    exe pgm

    dump_var "@compress"
    dump_var "@compress_level"

    write_to(file, 20)
  end

  def test_compress_level_error_1
    file = "compress_level.log"
    pgm = %{@logger.init("#{file}", "5K")}
    exe pgm

    pgm = "@logger.compress_level(-9)"
    exe pgm
  end

  def test_compress_level_error_2
    file = "compress_level.log"
    pgm = %{@logger.init("#{file}", "5K")}
    exe pgm

    pgm = %{@logger.compress_level("aaa")}
    exe pgm
  end

  def test_w_1
    file = "w.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %(rst @logger.w "aaa")
    exe pgm

    pgm = %{@logger.w 9.999}
    exe pgm
    pgm = %{@logger.w 9999}
    exe pgm

    func "ary = [111, 333, 555]"
    func "@logger.w ary"
    ary = [111, 333, 555]
    @logger.w ary

    dump_file file
  end

  def test_w_2
    file = "w.log"
    pgm = %{@logger.init("#{file}", "10K")}
    exe pgm

    write_to(file, 1000)
  end

  def test_w_3
    file = "w.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm
    
    pgm = %{@logger << "aaa"}
    exe pgm
    pgm = %{@logger <<"bbb"}
    exe pgm

    dump_file file
  end

  def test_w_4
    file = "w.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{rst @logger.file_closed?}
    exe pgm

    func %{@logger.e}
    @logger.e

    exe pgm
  end
    
  def test_w_5
    pgm = %{@logger.init(:STDOUT)}
    exe pgm

    pgm = %{rst @logger.file_closed?}
    exe pgm

    pgm = %{rst @logger.e}
    exe pgm

    pgm = %{rst @logger.flush}
    exe pgm

    pgm = %{rst @logger.reopen}
    exe pgm
  end

  def test_reopen_1
    file = "reopen.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{rst @logger.reopen}
    exe pgm

    pgm = "@logger.e"
    exe pgm

    pgm = %{rst @logger.file_closed?}
    exe pgm

    pgm = "rst @logger.reopen"
    exe pgm

    pgm = %{rst @logger.file_closed?}
    exe pgm

    pgm = %{@logger.w("test")}
    exe pgm

    dump_file file
  end

  def test_wflush_1
    info "This test expect don't call IO#flush"
    cmm "Please check this test, to change the original source"

    file = "wflush.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    dump_var "@enable_wflush"

    @logger << "wflush test"

    dump_file file
  end

  def test_wflush_2
    info "This test expect call IO#flush"
    cmm "Please check this test, to change the original source"

    file = "wflush.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.enable_wflush}
    exe pgm
 
    dump_var "@enable_wflush"

    @logger << "wflush test"

    dump_file file
  end

  def test_wflush_3
    info "This test expect don't call IO#flush"
    cmm "Please check this test, to change the original source"

    file = "wflush.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    dump_var "@enable_wflush"

    pgm = %{@logger.enable_wflush}
    exe pgm

    dump_var "@enable_wflush"

    pgm = %{@logger.disable_wflush}
    exe pgm

    dump_var "@enable_wflush"

    @logger << "wflush test"

    dump_file file
  end

  def test_flush_1
    file = "flush.log"
    pgm = %{@logger.init("#{file}", "5G")}
    exe pgm

    write_to(file, 50)
    write_to(file, 50)
    write_to(file, 50)
    pgm = %{@logger.flush}
    exe pgm
    write_to(file, 5)
    write_to(file, 5)
  end

  def test_flush_2
    file = "flush.log"
    pgm = %{@logger.init("#{file}", "DAILY")}
    exe pgm

    write_to(file, 50)
    pgm = %{rst @logger.flush}
    exe pgm
    write_to(file, 5)
  end

  def test_threshold_1
    file = "threshold.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{rst @logger.threshold}
    exe pgm
  end

  def test_threshold_2
    file = "threshold.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    info "now threshold is => #{@logger.threshold}"
    w_all_mode file
  end

  def test_threshold_3
    file = "threshold.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.threshold="DEBUG"}
    exe pgm

    info "now threshold is => #{@logger.threshold}"
    w_all_mode file
  end

  def test_threshold_4
    file = "threshold.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.threshold="INFO"}
    exe pgm

    info "now threshold is => #{@logger.threshold}"
    w_all_mode file
  end

  def test_threshold_5
    file = "threshold.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.threshold="WARN"}
    exe pgm

    info "now threshold is => #{@logger.threshold}"
    w_all_mode file
  end

  def test_threshold_6
    file = "threshold.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.threshold="ERROR"}
    exe pgm

    info "now threshold is => #{@logger.threshold}"
    w_all_mode file
  end

  def test_threshold_7
    file = "threshold.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.threshold="FATAL"}
    exe pgm

    info "now threshold is => #{@logger.threshold}"
    w_all_mode file
  end

  def test_threshold_error_1
    file = "threshold.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.threshold="FATALL"}
    exe pgm
    info "now threshold is => #{@logger.threshold}"

    pgm = %{@logger.w "test"}
    exe pgm
    dump_file file
  end

  def test_threshold_error_2
    file = "threshold.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.threshold=9999}
    exe pgm
    info "now threshold is => #{@logger.threshold}"

    pgm = %{@logger.w "test"}
    exe pgm
    dump_file file
  end

  def test_logging_1
    file = "logging.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{rst @logger.logging_format}
    exe pgm

    pgm = %{@logger.w("logging test")}
    exe pgm
    dump_file file

    pgm = %{@logger.logging_format = "[$LEVEL]:$DATE => [$LOG]($LEVEL) | $FILE | $FILE-FUL"}
    exe pgm

    pgm = %{rst @logger.logging_format}
    exe pgm

    pgm = %{@logger.fatal}
    exe pgm

    pgm = %{@logger.w("logging test")}
    exe pgm
    dump_file file
  end

  def test_date_1
    file = "date.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{rst @logger.date_format}
    exe pgm

    pgm = %{@logger.w("test")}
    exe pgm
    dump_file file

    pgm = %{@logger.date_format = "%y/%m/%d - %H:%M:%S"}
    exe pgm

    pgm = %{rst @logger.date_format}
    exe pgm

    pgm = %{@logger.w("test")}
    exe pgm
    dump_file file
  end

  def test_rename_1
    file = "rename.log"
    pgm = %{@logger.init("#{file}", "5K")}
    exe pgm

    pgm = %{rst @logger.rename_format}
    exe pgm

    pgm = %{@logger.rename_format=".nyanko."}
    exe pgm

    pgm = %{rst @logger.rename_format}
    exe pgm

    write_to(file, 100)
  end

  def test_rename_2
    pgm = %{rst @logger.rename_format}
    exe pgm

    pgm = %{@logger.rename_format=".nyanko."}
    exe pgm

    pgm = %{rst @logger.rename_format}
    exe pgm

    file = "rename.log"
    pgm = %{@logger.init("#{file}", "DAILY")}
    exe pgm

    pgm = %{@logger.w "daily"}
    exe pgm
    dump_file file

    go_back_logs_date file
  end

  def test_nowcheck_1
    file = "nowcheck.log"
    pgm = %{@logger.init("#{file}", "1K")}
    exe pgm
    write_to(file, 500)
  end

  def test_nowcheck_2
    file = "nowcheck.log"
    pgm = %{@logger.init("#{file}", "1K")}
    exe pgm

    exe %{@logger.no_wcheck}

    write_to(file, 500)
  end

  def test_silence_1
    file = "silence.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    exe %{@logger.reopen}

    exe %{@logger.aaa}
  end

  def test_silence_2
    file = "silence.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    exe %{@logger.silence}

    exe %{@logger.reopen}

    exe %{@logger.aaa}
  end

  def check_loglevel(pgm, answer)
    exe pgm
    dump_var "@log_level"
    loglevel = @logger.instance_variable_get("@log_level")
    assert(loglevel == answer, "ERROR => #{pgm}\n * loglevel => #{loglevel} (expected: #{answer})")
    info %{assert OK: "#{pgm}" changed @log_level correctly}
    exe %{@logger.w("test")}
  end

  def test_loglevel_1
    file = "loglevel.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    exe %{@logger.threshold = "DEBUG"}

    pgm = %{@logger.debug}
    check_loglevel(pgm, 1)
    dump_file file

    pgm = %{@logger.info}
    check_loglevel(pgm, 2)
    dump_file file

    pgm = %{@logger.warn}
    check_loglevel(pgm, 3)
    dump_file file

    pgm = %{@logger.error}
    check_loglevel(pgm, 4)
    dump_file file

    pgm = %{@logger.w "contine write"}
    exe pgm
    dump_file file

    pgm = %{@logger.fatal}
    check_loglevel(pgm, 5)
    dump_file file

    pgm = %{@logger.warn.w "warning"}
    exe pgm
    dump_file file
  end

  def dump_inode(file)
    info "current inode: #{File.stat(file).ino}"
    info "now open inode: #{@logger.instance_variable_get(:@logf).stat.ino}"
  end

  def change_inode(file)
    File.delete(file)
    tip "#{file} deleted"
    File.open(file, "w").close
    tip "#{file} created"
    tip "inode changed!"
    dump_inode file
  end

  def test_psafe_mode_1
    dump_var "@psafe_mode"
    dump_var "@enable_wflush"
    dump_var "@sleep_time"

    pgm = %{@logger.psafe_mode}
    exe pgm

    dump_var "@psafe_mode"
    dump_var "@enable_wflush"
    dump_var "@sleep_time"

    file = "psafe_mode.log"
    pgm = %{@logger.init("#{file}", "1M", 0)}
    exe pgm

    dump_var "@psafe_mode"
    dump_var "@enable_wflush"
    dump_var "@sleep_time"
  end

  def test_psafe_mode_2
    file = "psafe_mode.log"
    pgm = %{@logger.init("#{file}", "1M", 0)}
    exe pgm

    dump_var "@psafe_mode"
    dump_var "@enable_wflush"
    dump_var "@sleep_time"

    pgm = %{@logger.psafe_mode}
    exe pgm

    dump_var "@psafe_mode"
    dump_var "@enable_wflush"
    dump_var "@sleep_time"
  end

  def test_psafe_mode_3
    dump_var "@psafe_mode"
    dump_var "@enable_wflush"
    dump_var "@sleep_time"

    pgm = %{@logger.psafe_mode(10)}
    exe pgm

    file = "psafe_mode.log"
    pgm = %{@logger.init("#{file}", "1M", 0)}
    exe pgm

    dump_var "@psafe_mode"
    dump_var "@enable_wflush"
    dump_var "@sleep_time"
  end

  def test_sleep_time_1
    pgm = %{rst @logger.sleep_time}
    exe pgm

    pgm = %{@logger.sleep_time = 10}
    exe pgm

    pgm = %{rst @logger.sleep_time}
    exe pgm

    file = "psafe_mode.log"
    pgm = %{@logger.init("#{file}", "5K", 0)}
    exe pgm

    pgm = %{rst @logger.sleep_time}
    exe pgm

    pgm = %{@logger.sleep_time = 100}
    exe pgm

    pgm = %{rst @logger.sleep_time}
    exe pgm

    write_to(file, 20)
  end

  def test_sync_inode_1
    file = "sync_inode.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.w "old"}
    exe pgm
    dump_file file

    dump_inode file
    change_inode file

    pgm = "@logger.sync_inode"
    exe pgm

    dump_inode file

    pgm = %{@logger.w "new"}
    exe pgm
    dump_file file
  end

  def test_sync_inode_2
    file = "sync_inode.log"
    pgm = %{@logger.init(:STDOUT)}
    exe pgm

    pgm = "rst @logger.sync_inode"
    exe pgm

    pgm = "rst @logger.no_sync_inode"
    exe pgm
  end

  def test_no_sync_inode_1
    file = "no_sync.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.w "aaa"}
    exe pgm
    dump_file file

    pgm = %{@logger.w "bbb"}
    exe pgm
    dump_file file

    pgm = %{@logger.w "ccc"}
    exe pgm
    dump_file file
  end

  def test_no_sync_inode_2
    file = "no_sync.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.w "old"}
    exe pgm
    dump_file file

    dump_inode file
    change_inode file

    pgm = %{@logger.no_sync_inode}
    exe pgm

    dump_inode file
    pgm = %{@logger.w "new"}
    exe pgm
    dump_file file

    dump_inode file
    pgm = %{@logger.w "testtest"}
    exe pgm
    dump_file file
  end

  def test_auto_sync
    file = "auto_sync.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.w "old"}
    exe pgm
    dump_file file

    dump_inode file
    change_inode file

    pgm = %{@logger.w "new"}
    exe pgm
    dump_file file
  end

  def test_multi_thread_1
    file = "thread_safe.log"
    pgm = %{@logger.init("#{file}", "10M")}
    exe pgm

    list  = ["A", "B", "C", "D"]
    count = 10000
    loops = count.times

    info %{fork thread, #{list.join(",")}, write to file #{count} times!}

    Parallel.map(list, :in_threads => 4) do |n|
      for cnt in loops
        debug_info =  "Thread#{n}(#{cnt}) - #{Thread.current}"
        @logger.w(debug_info)
      end
      tip "Thread#{n} complete!"
    end
    @logger.e

    cmm %{ruby #{__FILE__} -n "test_grep_thread"}
  end

  def test_grep_thread
    file = "thread_safe.log"
    list = ["A", "B", "C", "D"]
    grep_thread(file, list)
  end

  def grep_thread(file, list)
    data = IO.readlines(file)
    list.each do |n|
      info "Count of Thread #{n} => "+data.grep(/#{n}/).size.to_s
    end
  end

  def multi_thread(file)
    list  = ["A", "B", "C", "D"]
    count = 10000
    loops = count.times

    info %{fork thread, #{list.join(",")}, write to file #{count} times!}

    Parallel.map(list, :in_threads => 4) do |n|
      for cnt in loops
        debug_info =  "Thread#{n}(#{cnt}) - #{Thread.current}"
        @logger.w debug_info
      end
      tip "Thread#{n} complete!"
    end
    @logger.e
  end

  def test_multi_thread_2
    file = "thread_safe.log"
    pgm = %{@logger.init("#{file}", "3M")}
    exe pgm

    multi_thread file
  end

  def test_multi_thread_3
    pgm = %{@logger.compress}
    exe pgm

    file = "thread_safe.log"
    pgm = %{@logger.init("#{file}", "3M")}
    exe pgm

    multi_thread file
  end

  def test_multi_thread_4
    file = "thread_safe.log"
    pgm = %{@logger.init("#{file}", "DAILY")}
    exe pgm

    multi_thread file
    go_back_logs_date file
  end

  def test_multi_thread_5
    pgm = %{@logger.compress}
    exe pgm

    file = "thread_safe.log"
    pgm = %{@logger.init("#{file}", "DAILY")}
    exe pgm

    multi_thread file
    go_back_logs_date file
  end

  def test_grep_process
    file = "process_safe.log"
    list = ["A", "B", "C", "D"]
    grep_process(file, list)
  end

  def grep_process(file, list)
    data = IO.readlines(file)
    list.each do |n|
      info "Count of Process #{n} => "+data.grep(/#{n}/).size.to_s
    end
  end

  def multi_process(file)
    list  = ["A", "B", "C", "D"]
    count = 10000
    loops = count.times

    info %{fork process, #{list.join(",")}, write to file #{count} times!}

    Parallel.map(list, :in_processes => 4) do |n|
      for cnt in loops
        debug_info =  "Process#{n}(#{cnt}) - #{Thread.current}"
        @logger.w(debug_info)
      end
      tip "Process#{n} complete!"
    end
    @logger.e
  end

  def test_multi_process_1
    pgm = %{@logger.psafe_mode}
    exe pgm

    file = "process_safe.log"
    pgm = %{@logger.init("#{file}", "10M")}
    exe pgm

    multi_process file

    cmm %{ruby #{__FILE__} -n "test_grep_process"}
  end

  def test_multi_process_2
    pgm = %{@logger.psafe_mode}
    exe pgm

    file = "process_safe.log"
    pgm = %{@logger.init("#{file}", "3M")}
    exe pgm

    multi_process file
  end

  def test_multi_process_3
    pgm = %{@logger.psafe_mode}
    exe pgm

    pgm = %{@logger.compress}
    exe pgm

    file = "process_safe.log"
    pgm = %{@logger.init("#{file}", "3M")}
    exe pgm

    multi_process file
  end

  def test_multi_process_4
    pgm = %{@logger.psafe_mode}
    exe pgm

    file = "process_safe.log"
    pgm = %{@logger.init("#{file}", "DAILY")}
    exe pgm

    multi_process file
    go_back_logs_date file
  end

  def test_multi_process_5
    pgm = %{@logger.compress}
    exe pgm

    pgm = %{@logger.psafe_mode}
    exe pgm

    file = "process_safe.log"
    pgm = %{@logger.init("#{file}", "DAILY")}
    exe pgm

    multi_process file
    go_back_logs_date file
  end

  def test_multi_process_6
    info "Disable process safe mode!!"

    tempf_dir = "/home/nyanko/logs"
    info "temp file will be not created at => #{tempf_dir}"
    file = "#{tempf_dir}/process_safe.log"

    pgm = %{@logger.init("#{file}")}
    exe pgm

    Dir.glob("#{tempf_dir}/.*").each do |fname|
      tip fname
    end

    pgm = %{@logger.w("psafe")}
    exe pgm
    dump_file file

    cmm "ls -ltrA #{tempf_dir}"
  end

  def test_multi_process_7
    pgm = %{@logger.psafe_mode}
    exe pgm

    tempf_dir = "/home/nyanko/logs"
    info "temp file will be created at => #{tempf_dir}"
    file = "#{tempf_dir}/process_safe.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    Dir.glob("#{tempf_dir}/.*").each do |fname|
      tip fname
    end

    pgm = %{@logger.w("psafe")}
    exe pgm
    dump_file file

    cmm "ls -ltrA #{tempf_dir}"
  end

  def test_multi_process_8
    tempf_dir = "/home/nyanko/logs"
    info "first, create temp file => #{tempf_dir}"
    tempf_name = "#{tempf_dir}#{File::SEPARATOR}.SimpleRotate_tempfile_#{File.basename($0)}"

    pgm = %{File.open("#{tempf_name}", "w").close}
    exe pgm

    Dir.glob("#{tempf_dir}/.*").each do |fname|
      tip fname
    end

    pgm = %{@logger.psafe_mode}
    exe pgm

    file = "#{tempf_dir}/process_safe.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.w("psafe")}
    exe pgm
    dump_file file

    cmm "ls -ltrA #{tempf_dir}"
  end

  def test_multi_process_9
    tempf_dir = "/home/nyanko/logs"
    info "first, create temp file & write it => #{tempf_dir}"
    tempf_name = "#{tempf_dir}#{File::SEPARATOR}.SimpleRotate_tempfile_#{File.basename($0)}"

    f = File.open(tempf_name, "w")
    f.puts "test"
    f.close

    dump_file tempf_name

    Dir.glob("#{tempf_dir}/.*").each do |fname|
      tip fname
    end

    pgm = %{@logger.psafe_mode}
    exe pgm

    file = "#{tempf_dir}/process_safe.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.w("psafe")}
    exe pgm
    dump_file file

    cmm "ls -ltrA #{tempf_dir}"
  end

  def test_multi_process_10
    pgm = %{@logger.psafe_mode}
    exe pgm

    tempf_dir = "/home/nyanko/logs"
    info "temp file will be created at => #{tempf_dir}"

    file = "#{tempf_dir}/process_safe.log"
    pgm = %{@logger.init("#{file}")}
    exe pgm

    pgm = %{@logger.w "old"}
    exe pgm
    dump_file file

    dump_inode file
    change_inode file

    pgm = %{@logger.w "new"}
    exe pgm
    dump_file file

    cmm "ls -ltrA #{tempf_dir}"
  end

  def test_multi_process_11
    file = "process_safe.log"
    if File.exists?(file)
      cmm ("#{file} is already exists! Please remove it!!")
      abort
    end

    list  = ["A", "B", "C", "D"]
    info %{fork process, #{list.join(",")}, create file same time!}

    Parallel.map(list, :in_processes => 4) do |n|
      pgm = %{@logger.psafe_mode}
      exe pgm

      file = "process_safe.log"
      pgm = %{@logger.init("#{file}", "10M")}
      exe pgm

      pgm = %{@logger.w("wrote #{n}")}
      exe pgm

      pgm = %{@logger.e}
      exe pgm
    end

    dump_file file
  end

  def test_multi_process_12
    file = "process_safe.log"
    info "Test case file exist pattern"
    f = File.open(file, "w")
    f.puts "===================================="
    f.close
    dump_file file

    list  = ["A", "B", "C", "D"]
    info %{fork process, #{list.join(",")}, create file same time!}

    Parallel.map(list, :in_processes => 4) do |n|
      pgm = %{@logger.psafe_mode}
      exe pgm

      file = "process_safe.log"
      pgm = %{@logger.init("#{file}", "10M")}
      exe pgm

      pgm = %{@logger.w("wrote #{n}")}
      exe pgm

      pgm = %{@logger.e}
      exe pgm
    end

    dump_file file
  end

  def test_multi_process_13
    file = "process_safe.log"

    list  = ["A", "B", "C", "D"]
    info %{fork process, #{list.join(",")}, create file same time!}

    Parallel.map(list, :in_processes => 4) do |n|
      pgm = %{@logger.psafe_mode}
      exe pgm

      file = "process_safe.log"
      pgm = %{@logger.init("#{file}", "10M")}
      exe pgm

      pgm = %{@logger.w("wrote #{n}")}
      exe pgm

      pgm = %{@logger.flush}
      exe pgm

      pgm = %{@logger.e}
      exe pgm
    end
  end

  def test_no_init_1
    @logger.w "test"
  end

  def test_delete_header_1
    file = "delete_header.log"
    pgm = %{@logger.init("#{file}", "5K")}
    exe pgm

    write_to(file, 20)
  end

  def test_delete_header_2
    file = "delete_header.log"
    pgm = %{@logger.init("#{file}", "DAILY")}
    exe pgm

    write_to(file, 20)
  end
end

MiniTest::Unit.autorun

