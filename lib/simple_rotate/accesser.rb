#--------------------
# access definitions
#--------------------
class SimpleRotate
    attr_accessor :threshold,
                  :date_format,
                  :logging_format,
                  :rename_format,
                  :allow_overwrite,
                  :sleep_time

    attr_reader   :limit
end
