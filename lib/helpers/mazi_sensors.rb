SENSORS_DB_IP      = 'localhost'                 # this should be localhost
SELECT_QUERY_LIMIT = 'GROUP BY id DESC LIMIT 50' # default query for the select on the sensors db
SENSORS_ENABLED    = true                        # a quick way to disable the sensors module

module MaziSensors
  def init_sensors
    con = Mysql.new(SENSORS_DB_IP, 'mazi_user', '1234', 'sensors')
    @sensors_enabled = true
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    @sensors_enabled = false
  ensure
    con.close if con
  end

  def initialize_sensors_module(password)
    `sh /root/back-end/mazi-sense.sh --init #{password}`
    con = Mysql.new(SENSORS_DB_IP, 'mazi_user', '1234', 'sensors')
    i = 1
    `sh /root/back-end/mazi-sense.sh -a`.split("\n").each do |line|
      line = line.split
      con.query("INSERT INTO type(name, ip) VALUES('#{line[0]}', '#{line[2]}')")
      con.query("CREATE TABLE IF NOT EXISTS sensor_#{i}(id INT PRIMARY KEY AUTO_INCREMENT, time DATETIME, temperature VARCHAR(4), humidity VARCHAR(4))")
      i += 1
    end
    @sensors_enabled = true
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL."
    @sensors_enabled = false
  ensure
    con.close if con
  end

  def sensors_enabled?
    SENSORS_ENABLED && @config[:sensors] && @config[:sensors][:enable] && @sensors_enabled
  end

  def sensors_db_exist?
    con = Mysql.new(SENSORS_DB_IP, 'mazi_user', '1234', 'sensors')
    @sensors_enabled = true
    true
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    @sensors_enabled = false
    false
  ensure
    con.close if con
  end

  def toggle_sensors_enabled
    current_value = @config[:sensors][:enable]
    changeConfigFile("sensors->enable", !current_value)
    writeConfigFile
  end

  def getAllAvailableSensors
    if @config[:general][:mode] == 'demo'
      return [{type: 'sensehat', status: 'active', id: 1, ip: '10.0.0.1', nof_entries: 12}, {type: 'sht11', status: 'not found', id: 2, ip: '10.0.0.1', nof_entries: 0}]
    end
    con = Mysql.new(SENSORS_DB_IP, 'mazi_user', '1234', 'sensors')
    result = []
    `sh /root/back-end/mazi-sense.sh -a`.split("\n").each do |line|
      line = line.split
      q = "SELECT * FROM type WHERE ip = '#{line[2]}'"
      a = con.query(q)
      entry_exists = false
      a.each_hash do |h|
        if h['name'] == line[0] # this is the type
          entry_exists = true
          q2 = "SELECT * FROM sensor_#{h['id']}"
          a2 = con.query(q2)
          result << {id: h['id'], type: h['name'], ip: h['ip'], status: line[1], nof_entries: a2.num_rows}
        end
      end
      unless entry_exists
        con.query("INSERT INTO type(name, ip) VALUES('#{line[0]}', '#{line[2]}')")
        a = con.query("SELECT * FROM type WHERE ip = '#{line[2]}'")
        a.each_hash do |h|
          if h['name'] == line[0]
            con.query("CREATE TABLE IF NOT EXISTS sensor_#{h['id']}(id INT PRIMARY KEY AUTO_INCREMENT, time DATETIME, temperature VARCHAR(4), humidity VARCHAR(4))")
            result << {id: h['id'], type: h['name'], ip: h['ip'], status: line[1], nof_entries: 0}
          end
        end
      end
    end
    return result
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    return []
  ensure 
    con.close if con
  end

  def getTemperatures(id, start_time=nil, end_time=nil)
    if @config[:general][:mode] == 'demo'
      return [{date: '2012-10-01', temp: 30}, {date: '2012-10-02', temp: 31}, {date: '2012-10-03', temp: 32}, {date: '2012-10-04', temp: 29}, {date: '2012-10-05', temp: 28}, {date: '2012-10-06', temp: 25}, {date: '2012-10-07', temp: 32}, {date: '2012-10-08',temp: 33}, {date: '2012-10-09', temp: 17}, {date: '2012-10-10', temp: 19}, {date: '2012-10-11', temp: 21}, {date: '2012-10-12', temp: 24}, {date: '2012-10-13', temp: 20}, {date: '2012-10-14', temp: 18}, {date: '2012-10-15', temp: 32}, {date: '2012-10-16', temp: 24}, {date: '2012-10-17', temp: 15}, {date: '2012-10-18', temp: 14}, { date: '2012-10-19', temp: -11}, {date: '2012-10-20', temp: -12}, {date: '2012-10-21', temp: 29}, {date: '2012-10-22', temp: 31}, {date: '2012-10-23', temp: 15}, {date: '2012-10-24', temp: 16}, {date: '2012-10-25', temp: 17}, {date: '2012-10-26', temp: 18}, {date: '2012-10-27', temp: 19}, {date: '2012-10-28', temp: 20}, {date: '2012-10-29', temp: 21}, {date: '2012-10-30', temp: 22}, {date: '2012-10-31', temp: 50}]
    end

    sensors_con = Mysql.new(SENSORS_DB_IP, 'mazi_user', '1234', 'sensors')
    if start_time == '*' && end_time == '*'
      q = "SELECT * FROM sensor_#{id}"
    elsif start_time == '*'
      q = "SELECT * FROM sensor_#{id} WHERE time <= '#{end_time}'"
    elsif end_time == '*'
      q = "SELECT * FROM sensor_#{id} WHERE time >= '#{start_time}'"
    elsif start_time.nil? && end_time.nil?
      q = "SELECT * FROM sensor_#{id} #{SELECT_QUERY_LIMIT}"
    elsif start_time && end_time
      q = "SELECT * FROM sensor_#{id} WHERE time >= '#{start_time}' AND time <= '#{end_time}'"
    else
      q = "SELECT * FROM sensor_#{id}"
    end

    a = sensors_con.query(q)
    result = []
    a.each_hash do |h|
      result << {date: h['time'], temp: h['temperature']}
    end
    return result
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    return nil
  ensure 
    sensors_con.close if sensors_con
  end

  def getHumidities(id, start_time=nil, end_time=nil)
    if @config[:general][:mode] == 'demo'
      return [{date: '2012-10-01', hum: 55}, {date: '2012-10-02', hum: 56}, {date: '2012-10-03', hum: 58}, {date: '2012-10-04', hum: 70}, {date: '2012-10-05', hum: 60}, {date: '2012-10-06', hum: 65}, {date: '2012-10-07', hum: 45}, {date: '2012-10-08',hum: 44}, {date: '2012-10-09', hum: 39}, {date: '2012-10-10', hum: 49}, {date: '2012-10-11', hum: 54}, {date: '2012-10-12', hum: 53}, {date: '2012-10-13', hum: 54}, {date: '2012-10-14', hum: 60}, {date: '2012-10-15', hum: 70}, {date: '2012-10-16', hum: 77}, {date: '2012-10-17', hum: 78}, {date: '2012-10-18', hum: 79}, { date: '2012-10-19', hum: 80}, {date: '2012-10-20', hum: 81}, {date: '2012-10-21', hum: 82}, {date: '2012-10-22', hum: 83}, {date: '2012-10-23', hum: 45}, {date: '2012-10-24', hum: 46}, {date: '2012-10-25', hum: 50}, {date: '2012-10-26', hum: 50}, {date: '2012-10-27', hum: 50}, {date: '2012-10-28', hum: 50}, {date: '2012-10-29', hum: 50}, {date: '2012-10-30', hum: 50}, {date: '2012-10-31', hum: 99}]
    end

    sensors_con = Mysql.new(SENSORS_DB_IP, 'mazi_user', '1234', 'sensors')
    if start_time == '*' && end_time == '*'
      q = "SELECT * FROM sensor_#{id}"
    elsif start_time == '*'
      q = "SELECT * FROM sensor_#{id} WHERE time <= '#{end_time}'"
    elsif end_time == '*'
      q = "SELECT * FROM sensor_#{id} WHERE time >= '#{start_time}'"
    elsif start_time.nil? && end_time.nil?
      q = "SELECT * FROM sensor_#{id} #{SELECT_QUERY_LIMIT}"
    elsif start_time && end_time
      q = "SELECT * FROM sensor_#{id} WHERE time >= '#{start_time}' AND time <= '#{end_time}'"
    else
      q = "SELECT * FROM sensor_#{id}"
    end

    a = sensors_con.query(q)
    result = []
    a.each_hash do |h|
      result << {date: h['time'], hum: h['humidity']}
    end
    return result
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    return nil
  ensure 
    sensors_con.close if sensors_con
  end

  def start_sensing(sensor_name, duration = 1800, interval = 30)
    MaziLogger.debug "start sensing: #{sensor_name} - #{duration} - #{interval}"

    Thread.new do 
      `sh /root/back-end/mazi-sense.sh -n #{sensor_name} -t -h -s -d #{duration} -i #{interval}`
    end
    sleep 1
    true
  end

  def delete_measurements(sensor_id)
  
    sensors_con = Mysql.new(SENSORS_DB_IP, 'mazi_user', '1234', 'sensors')
    q = "TRUNCATE sensor_#{sensor_id}"
    sensors_con.query(q)

  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    return nil
  ensure 
    sensors_con.close if sensors_con
  end
end