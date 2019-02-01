require 'open3'

class MaziExecCmd
  class ScriptNotEnabled < StandardError
  end

  def initialize(env, path, cmd, args=[], enabled_scripts=[], demo=false)
    @enabled_scripts = enabled_scripts
    @demo = demo == "demo"
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
    return demoExec if @demo
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
    return demoParse(token, splitter) if @demo
    @output.each do |line|
      return line.split(splitter) if line.include? token
    end
    false
  end

  def parseForAll(token, splitter=' ')
    return demoParse(token, splitter) if @demo
    out = []
    @output.each do |line|
      out << line.split(splitter) if line.include? token
    end
    out.empty? ? false : out
  end

  def demoExec
    case @cmd
    when 'wifiap.sh'
      'OK'
    when 'current.sh'
      'OK'
    when 'internet.sh'
      'OK'
    when 'antenna.sh'
      'OK'
    when 'mazi-app.sh'
      'OK'
    when 'mazi-stat.sh'
      if @args.include? '-t'
        'temp=68.2\'C'
      elsif @args.include? '-c'
        ['30.1%']
      elsif @args.include? '-r'
        ['49.5%']
      elsif @args.include? '-s'
        ['38.0%']
      else
        'wifi users 3'
      end
    end
  end

  def demoParse(token, splitter)
    case @cmd
    when 'wifiap.sh'
      'OK'
    when 'current.sh'
      case token
      when 'ssid'
        return ['ssid', 'MAZIZONE']
      when 'channel'
        return ['channel', '6']
      when 'password'
        return ['password', '123456789']
      when 'mode'
        return ['mode', 'offline']
      when 'interface'
        return [{:wlan0=>{:interface=>"wlan0", :name=>"Raspberry WiFi111", :mode=>"wifi"}}]
      end
    when 'internet.sh'
      'OK'
    when 'antenna.sh'
      'OK'
    when 'mazi-app.sh'
      'OK'
    when 'mazi-stat.sh'
      if @args.include? '-t'
        return ['temp=68.2', "C"]
      elsif @args.include? '-c'
        return ['30.1', '%']
      elsif @args.include? '-r'
        return ['49.5', '%']
      elsif @args.include? '-s'
        return ['38.0', '%']
      else
        return ['wifi', 'users', '3']
      end
    end
  end
end
