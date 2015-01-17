class Index
  attr_accessor :files

  def initialize(options = {})
    @target_dir = Pathname.new options[:target_dir] || '.'
    @index_location = options[:index_location] || 'index'
    @files = []
  end

  def index_file(mode: 'r')
    @index_file ||= File.open @index_location, mode
  end

  def load
    index_file.each_line do |line|
      line.split(' | ').tap do |path, md5|
        @files << [ Pathname.new(path), md5.chomp ]
      end
    end
  rescue Errno::ENOENT
    return false
  else
    close
    true
  end

  def save
    scan if files.empty?

    files.each do |data|
      index_file(mode: 'w').write "#{data[0]} | #{data[1]}\n"
    end

    close
    self
  end

  def scan(target = @target_dir)
    target.each_child do |pathname|
      if pathname.file?
        @files << [ pathname, Digest::MD5.file(pathname) ]
      elsif pathname.directory?
        scan pathname
      end
    end

    self
  end

  private

  def close
    index_file.close
    @index_file = nil
  end
end
