class SimpleRotate
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
end
