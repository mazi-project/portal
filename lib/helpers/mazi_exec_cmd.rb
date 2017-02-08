require 'open3'
# require './mazi_logger'

class MaziExecCmd
  class ScriptNotEnabled < StandardError 
  end

  def initialize(env, path, cmd, args=[], enabled_scripts=[])
    @enabled_scripts = enabled_scripts
    raise ScriptNotEnabled unless enabled?(cmd)
    @cmd = cmd
    @env = env
    @args = args
    @path = path
    @output = []
  end

  def enabled?(cmd)
    return true if @enabled_scripts.include?(cmd)
    false
  end

  def exec_command
    command = "#{@env} #{@path}#{@cmd} #{@args.join(' ')}"
    MaziLogger.debug "$ #{command}"
    @output = []
    Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
      while line = stdout.gets
        MaziLogger.debug "> #{line.strip}"
        @output << line.strip
      end
    end
    @output
  end

  def parseFor(token, splitter=' ')
    @output.each do |line|
      return line.split(splitter) if line.include? token
    end
    false
  end
end

# class TestCmd
#   include MaziExecCmd
# end

# t = TestCmd.new('', '', 'ls', ['-l'])

# out = t.exec_command

# puts "== #{out}"

# puts "-- #{t.parseFor('mazi_')}"

# puts "-- #{t.parseFor('aaaaaaa')}"
