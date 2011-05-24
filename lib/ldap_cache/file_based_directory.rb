module LDAPCache
  # refactored from ldapserver example 3
  class FileBasedDirectory
    attr_reader :data

    def initialize(filename)
      @filename = filename
      @stat = nil
      update
    end

    # synchronise with directory on disk (re-read if it has changed)

    def update
      begin
        tmp = {}
        sb = File.stat(@filename)
        return if @stat and @stat.ino == sb.ino and @stat.mtime == sb.mtime
        File.open(@filename) do |f|
          tmp = YAML::load(f.read)
          @stat = f.stat
        end
      rescue Errno::ENOENT
      end
      @data = tmp
    end

    # write back to disk

    def write
      File.open(@filename+".new","w") { |f| f.write(YAML::dump(@data)) }
      File.rename(@filename+".new",@filename)
      @stat = File.stat(@filename)
    end

    # run a block while holding a lock on the database

    def lock
      File.open(@filename+".lock","w") do |f|
        f.flock(File::LOCK_EX)  # will block here until lock available
        yield
      end
    end
  end
end
