require_relative "./process_sync_mixin"

class SimpleRotate
    class ProcessSync
        include ProcessSyncMixin

        ProcessSyncMixin.instance_methods.each do |method_name|
            method = instance_method(method_name)
            define_method(method_name) do |*args|
                # common execution
                return nil if !@enable
                # -------------------

                method.bind(self).call(*args)
            end
        end

        def initialize(sr)
            @sr          = sr
            @enable      = sr.instance_variable_get(:@is_psync)
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
end
