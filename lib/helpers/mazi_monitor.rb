module MaziMonitor
  def toggle_monitoring_enable
    current_value = @config[:monitoring][:enable]
    changeConfigFile("monitoring->enable", !current_value)
    writeConfigFile
  end

  def toggle_hardware_monitoring_enable
    current_value = @config[:monitoring][:hardware_enable]
    changeConfigFile("monitoring->hardware_enable", !current_value)
    writeConfigFile
  end

  def toggle_applications_monitoring_enable
    current_value = @config[:monitoring][:applications_enable]
    changeConfigFile("monitoring->applications_enable", !current_value)
    writeConfigFile
  end

  def disable_monitorings
    changeConfigFile("monitoring->applications_enable", false)
    changeConfigFile("monitoring->hardware_enable", false)
    writeConfigFile
  end

  def get_monitoring_details
    JSON.parse(File.read('/etc/mazi/mazi.conf'), symbolize_names: true)
  end

  def write_monitoring_details(details)
    old_details = JSON.parse(File.read('/etc/mazi/mazi.conf'), symbolize_names: true)
    details.each do |key, value|
      old_details[key.to_sym] = value
    end
    File.open("/etc/mazi/mazi.conf","w") do |f|
      f.write(old_details.to_json)
    end
  end

  def start_hardware_monitoring(url, parameters)
    command = "sh /root/back-end/mazi-stat.sh #{parameters} --store enable #{"-d #{url}" unless url == 'localhost'}"
    Thread.new do
      `#{command}`
    end
  end

  def stop_hardware_monitoring
    command = "sh /root/back-end/mazi-stat.sh --store disable"
    Thread.new do
      sleep 0.5
      `#{command}`
    end
    sleep 0.2
  end

  def start_application_monitoring(url, parameters)
    command = "sh /root/back-end/mazi-appstat.sh #{parameters} --store enable #{"-d #{url}" unless url == 'localhost'}"
    Thread.new do
      `#{command}`
    end
  end

  def stop_application_monitoring
    command = "sh /root/back-end/mazi-appstat.sh --store disable"
    Thread.new do
      sleep 0.5
      `#{command}`
    end
    sleep 0.2
  end

  def get_hardware_monitoring_status
    command = "sh /root/back-end/mazi-stat.sh --status"
    out = `#{command}`
    output = {}
    overall = false
    out.split("\n").each do |line|
      output[line.split.first] = line.split.last
      overall = true if line.split.last == 'active'
    end
    output['overall'] = overall
    output
  end

  def get_application_monitoring_status
    command = "sh /root/back-end/mazi-appstat.sh --status"
    out = `#{command}`
    output = {}
    overall = false
    out.split("\n").each do |line|
      output[line.split.first] = line.split.last
      overall = true if line.split.last == 'active'
    end
    output['overall'] = overall
    output
  end

  def get_nof_application_data_entries
    file  = File.read('/etc/mazi/sql.conf')
    data  = JSON.parse(file)
    file2 = File.read('/etc/mazi/mazi.conf')
    data2 = JSON.parse(file2)
    output = {}
    begin
      con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "#{data2["deployment"]}")
      results = con.query("SHOW TABLE STATUS")
      results.each do | row |
        output[row.first] = row[4] if row.first == 'etherpad' || row.first == 'guestbook' || row.first == 'framadate'
      end
      return output
    rescue Mysql::Error => e
      MaziLogger.error e.message
    ensure
      con.close if con
    end
  end

  def get_nof_hardware_data_entries
    file  = File.read('/etc/mazi/sql.conf')
    data  = JSON.parse(file)
    file2 = File.read('/etc/mazi/mazi.conf')
    data2 = JSON.parse(file2)
    output = {}
    begin
      con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "#{data2["deployment"]}")
      results = con.query("SHOW TABLE STATUS")
      results.each do | row |
        output[row.first] = row[4] if row.first == 'statistics' || row.first == 'users'
      end
      return output
    rescue Mysql::Error => e
      MaziLogger.error e.message
    ensure
      con.close if con
    end
  end

  def flush_hardware_data
    command = "sh /root/back-end/mazi-stat.sh --store flush"
    Thread.new do
      `#{command}`
    end
    sleep 5
  end

  def flush_application_data
    command1 = "sh /root/back-end/mazi-appstat.sh -n etherpad --store flush"
    command2 = "sh /root/back-end/mazi-appstat.sh -n guestbook --store flush"
    command3 = "sh /root/back-end/mazi-appstat.sh -n framadate --store flush"
    Thread.new do
      `#{command1}`
      `#{command2}`
      `#{command3}`
    end
    sleep 5
  end
end