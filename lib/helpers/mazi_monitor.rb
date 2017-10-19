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
    puts command.inspect
    Thread.new do
      `#{command}`
    end
  end

  def stop_hardware_monitoring
    command = "sh /root/back-end/mazi-stat.sh --store disable"
    `#{command}`
  end

  def start_application_monitoring(url, parameters)
    command = "sh /root/back-end/mazi-appstat.sh #{parameters} --store enable #{"-d #{url}" unless url == 'localhost'}"
    puts command.inspect
    Thread.new do
      `#{command}`
    end
  end

  def stop_application_monitoring
    command = "sh /root/back-end/mazi-appstat.sh --store disable"
    `#{command}`
  end

  def get_hardware_monitoring_status
    'inactive'
  end

  def get_application_monitoring_status
    'inactive'
  end
end