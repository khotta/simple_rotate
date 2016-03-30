class SimpleRotate
    class Error < RuntimeError
        msg  = "Aborted the log files rotation,"
        msg += " an unexpected error has occured."
        ROTATION_FAILED = msg

        @@silence = false

        # skip warning message
        def self.silence
            @@silence = true
        end

        # argument error
        def self.argv(param, argv)
            msg = "'#{param}'='#{argv}' is invalid argument value!"
            self.throw_error(msg)
        end

        # method missing
        def self.missing(name)
            msg = "undifined method 'SimpleRotate##{name}'"
            self.throw_error(msg)
        end

        # file open error
        def self.open(name)
            msg = "Couldn't open a '#{name}'"
            self.throw_error(msg)
        end

        # load error
        def self.load(name)
            msg = "Couldn't load a '#{name}'"
            self.throw_error(msg)
        end

        # exist error
        def self.exist(name, type)
            msg = "Already exists this #{type} => '#{name}'"
            self.throw_error(msg)
        end

        # warning - don't throw error
        def self.warning(msg)
            warn "[WARNING] #{msg} - (SimpleRotate::Error)" if !@@silence
        end

        # @param msg string
        def self.throw_error(msg)
            exeption = self.new(msg)
            warn exeption.message if !@@silence
            raise SimpleRotate::Error
        end
    end
end
