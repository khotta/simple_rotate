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
