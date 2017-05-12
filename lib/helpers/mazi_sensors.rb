require 'mysql'

SENSORS_DB_IP      = '10.64.45.90' #this should be localhost
SELECT_QUERY_LIMIT = 'GROUP BY id DESC LIMIT 50'

module MaziSensors
  def init_sensors
    # @sensors_con = Mysql.new(SENSORS_DB_IP, 'mazi_user', '1234', 'sensors')
    # a = @sensors_con.query("SELECT * FROM sensor_1 GROUP BY id DESC LIMIT 10")
    # puts "== #{a.inspect}"
    # # a.times do 
    # #   puts "-- #{a.fetch_hash.inspect}"
    # # end
    # a.each_hash do |h|
    #   puts "-- #{h.inspect}"
    # end
  # rescue Mysql::Error => ex
  #   MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
  #   @sensors_con = nil
  end

  def getTemperatures(start_time=nil, end_time=nil)
    if @config[:general][:mode] == 'demo'
      return [{date: '2012-10-01', temp: 30}, {date: '2012-10-02', temp: 31}, {date: '2012-10-03', temp: 32}, {date: '2012-10-04', temp: 29}, {date: '2012-10-05', temp: 28}, {date: '2012-10-06', temp: 25}, {date: '2012-10-07', temp: 32}, {date: '2012-10-08',temp: 33}, {date: '2012-10-09', temp: 17}, {date: '2012-10-10', temp: 19}, {date: '2012-10-11', temp: 21}, {date: '2012-10-12', temp: 24}, {date: '2012-10-13', temp: 20}, {date: '2012-10-14', temp: 18}, {date: '2012-10-15', temp: 32}, {date: '2012-10-16', temp: 24}, {date: '2012-10-17', temp: 15}, {date: '2012-10-18', temp: 14}, { date: '2012-10-19', temp: -11}, {date: '2012-10-20', temp: -12}, {date: '2012-10-21', temp: 29}, {date: '2012-10-22', temp: 31}, {date: '2012-10-23', temp: 15}, {date: '2012-10-24', temp: 16}, {date: '2012-10-25', temp: 17}, {date: '2012-10-26', temp: 18}, {date: '2012-10-27', temp: 19}, {date: '2012-10-28', temp: 20}, {date: '2012-10-29', temp: 21}, {date: '2012-10-30', temp: 22}, {date: '2012-10-31', temp: 50}]
    end

    sensors_con = Mysql.new(SENSORS_DB_IP, 'mazi_user', '1234', 'sensors')
    if start_time == '*' && end_time == '*'
      q = "SELECT * FROM sensor_1"
    elsif start_time == '*'
      q = "SELECT * FROM sensor_1 WHERE time <= '#{end_time}'"
    elsif end_time == '*'
      q = "SELECT * FROM sensor_1 WHERE time >= '#{start_time}'"
    elsif start_time.nil? && end_time.nil?
      q = "SELECT * FROM sensor_1 #{SELECT_QUERY_LIMIT}"
    elsif start_time && end_time
      q = "SELECT * FROM sensor_1 WHERE time >= '#{start_time}' AND time <= '#{end_time}'"
    else
      q = "SELECT * FROM sensor_1"
    end

    a = sensors_con.query(q)
    result = []
    a.each_hash do |h|
      result << {date: h['time'], temp: h['temperature']}
    end
    return result
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    return nil
  ensure 
    sensors_con.close if sensors_con
  end

  def getHumidities(start_time=nil, end_time=nil)
    if @config[:general][:mode] == 'demo'
      return [{date: '2012-10-01', hum: 55}, {date: '2012-10-02', hum: 56}, {date: '2012-10-03', hum: 58}, {date: '2012-10-04', hum: 70}, {date: '2012-10-05', hum: 60}, {date: '2012-10-06', hum: 65}, {date: '2012-10-07', hum: 45}, {date: '2012-10-08',hum: 44}, {date: '2012-10-09', hum: 39}, {date: '2012-10-10', hum: 49}, {date: '2012-10-11', hum: 54}, {date: '2012-10-12', hum: 53}, {date: '2012-10-13', hum: 54}, {date: '2012-10-14', hum: 60}, {date: '2012-10-15', hum: 70}, {date: '2012-10-16', hum: 77}, {date: '2012-10-17', hum: 78}, {date: '2012-10-18', hum: 79}, { date: '2012-10-19', hum: 80}, {date: '2012-10-20', hum: 81}, {date: '2012-10-21', hum: 82}, {date: '2012-10-22', hum: 83}, {date: '2012-10-23', hum: 45}, {date: '2012-10-24', hum: 46}, {date: '2012-10-25', hum: 50}, {date: '2012-10-26', hum: 50}, {date: '2012-10-27', hum: 50}, {date: '2012-10-28', hum: 50}, {date: '2012-10-29', hum: 50}, {date: '2012-10-30', hum: 50}, {date: '2012-10-31', hum: 99}]
    end

    sensors_con = Mysql.new(SENSORS_DB_IP, 'mazi_user', '1234', 'sensors')
    if start_time == '*' && end_time == '*'
      q = "SELECT * FROM sensor_1"
    elsif start_time == '*'
      q = "SELECT * FROM sensor_1 WHERE time <= '#{end_time}'"
    elsif end_time == '*'
      q = "SELECT * FROM sensor_1 WHERE time >= '#{start_time}'"
    elsif start_time.nil? && end_time.nil?
      q = "SELECT * FROM sensor_1 #{SELECT_QUERY_LIMIT}"
    elsif start_time && end_time
      q = "SELECT * FROM sensor_1 WHERE time >= '#{start_time}' AND time <= '#{end_time}'"
    else
      q = "SELECT * FROM sensor_1"
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
end