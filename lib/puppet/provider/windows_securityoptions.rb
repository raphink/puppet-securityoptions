require 'puppet/util/windows'

begin
  require File.expand_path('../../util/ini_file', __FILE__)
rescue LoadError
  # in case we're not in libdir
  require File.expand_path('../../../../spec/fixtures/modules/inifile/lib/puppet/util/ini_file', __FILE__)
end

class Puppet::Provider::Windows_SecurityOptions < Puppet::Provider
  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    write_export(@resource[:name], @resource[:sid])
    @property_hash[:ensure] = :present
  end

  def destroy
    write_export(@resource[:name], [])
    @property_hash[:ensure] = :absent
  end

  def flush
    tmp_sdb_file = File.join(Puppet[:vardir], 'secedit.sdb').gsub('/', '\\')
    secedit('/configure', '/db', tmp_sdb_file, '/cfg', in_file_path)
  end

  def self.attr_so_reader(name)
    define_method(name) do
      @property_hash[name.to_sym]
    end
  end

  def self.attr_so_writer(name)
    define_method("#{name}=") do |value|
      write_export(@resource[:name], value)
      @property_hash[name.to_sym] = value
    end
  end

  def self.attr_so_accessor(name)
    attr_so_reader(name)
    attr_so_writer(name)
  end



  def in_file_path
    option = @resource[:name].scan(/[\da-z]/i).join
    File.join(Puppet[:vardir], write_export_filename, "#{option}.txt").gsub('/', '\\')
  end

  def map_option(option)
    option
  end

  def map_value(option, value)
    [value]
  end

  def write_export_filename
    fail "write_export_filename needs to be implemented"
  end

  def section_name
    fail "section_name needs to be implemented"
  end

  def write_export(option, value)
    dir = File.join(Puppet[:vardir], write_export_filename)
    Dir.mkdir(dir) unless Dir.exist?(dir)

    File.open(in_file_path, 'w') do |f|
      f.write <<-EOF
[Unicode]
Unicode=yes
[#{section_name}]
#{map_option(option)} = #{map_value(option, value).join(',')}
[Version]
signature="$CHICAGO$"
Revision=1
      EOF
    end
  end
end