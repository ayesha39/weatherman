# frozen_string_literal:true

require 'date'
require 'colorize'
class Integer
  N_BYTES = [42].pack('i').size
  N_BITS = N_BYTES * 16
  MAX = 2**(N_BITS - 2) - 1
  MIN = -MAX - 1
end

module FileOperations
  def create_filename
    begin
      month = Date::MONTHNAMES[ARGV[1].split('/')[1].to_i]
      "#{ARGV[2].split('/')[1]}_#{ARGV[1].split('/')[0]}_#{month[0..2]}.txt"
    rescue StandardError => e
      puts 'invalid arguments'
    end
  end

  def file_reading(filename)
    record = []
    begin
      Dir.chdir ARGV[2]
      Dir.glob(filename).each do |file|
        fileline = File.readlines(file)
        fileline[0].strip.empty? ? fileline.shift(2) : fileline.shift(1)
        fileline.pop
        fileline.each do |line|
          record << line.split(',')
        end
      end
    rescue StandardError => e
      puts 'invalid arguments'
    end
    record
  end
end

class WeatherMan
  include FileOperations
  def main_function
    return 'invalid no of arguments: Three arguments required' if ARGV.length != 3

    return false unless valid_arguments

    case ARGV.first
    when '-e'
      max_year_temp
    when '-a'
      avg_month_temp
    when '-c'
      bar_chart_temp
    else
      puts 'invalid arguments'
    end
  end

  def valid_arguments
    unless File.directory?(ARGV[2])
      puts 'invalid arguments'
      return false
    end
    true
  end

  def max_year_temp
    max_array = file_reading("#{ARGV[2].split('/')[1]}_#{ARGV[1]}_*.txt")
    return 'no data for this year avaliable' if max_array.length.zero?

    highest_temp, lowest_temp = max_min_temp(max_array)
    humidity = humidity(max_array)
    puts "Highest: #{highest_temp[1]}C on #{convert_num_to_date(highest_temp[0])}"
    puts "Lowest: #{lowest_temp[3]}C on #{convert_num_to_date(lowest_temp[0])}"
    puts "humid: #{humidity[7]}% on #{convert_num_to_date(humidity[0])}"
  end

  def convert_num_to_date(num_date)
    month = Date::MONTHNAMES[num_date.split('-')[1].to_i]
    day = num_date.split('-')[2]
    "#{month} #{day}"
  end

  def avg_month_temp
    avg_month_array = file_reading(create_filename)
    return 'no data for this month avaliable' if avg_month_array.length.zero?

    sum_highest_temp, sum_lowest_temp, sum_humid = avg_temp(avg_month_array)
    puts "Highest Average: #{sum_highest_temp / avg_month_array.size}C"
    puts "Lowest Average: #{sum_lowest_temp / avg_month_array.size}C"
    puts "Average humidity: #{sum_humid / avg_month_array.size}%"
  end

  def bar_chart_temp
    bar_month_array = file_reading(create_filename)
    return 'no data for this month avaliable' if bar_month_array.length.zero?

    bar_month_array.each do |x|
      day = x[0].split('-')[2]
      day.prepend('0') if day.to_i.between?(1, 9)
      display_temp(day, x)
    end
    puts
  end

  def display_temp(day, x)
    high_temp = get_temp_row(x[1].to_i)
    low_temp = get_temp_row(x[3].to_i)
    puts "#{day} #{high_temp.red}" + x[1].to_i.to_s
    puts "#{day} #{low_temp.blue}" + x[3].to_i.to_s
  end

  def get_temp_row(count)
    character_string = ''
    count.times { character_string += '+' }
    character_string
  end

  def max_min_temp(array)
    max_arr = copy_array(array)
    min_arr = copy_array(array)
    max = max_arr.max_by do |i|
      i[1].empty? ? i[1] = Integer::MIN : i[1].to_i
    end
    min = min_arr.min_by do |i|
      i[3].empty? ? i[3] = Integer::MAX : i[3].to_i
    end
    [max, min]
  end

  def humidity(max_array)
    max_array.max_by { |i| i[7].to_i }
  end

  def copy_array(orig_array)
    copy_arr = []
    orig_array.each { |sub| copy_arr << sub.dup }
    copy_arr
  end

  def avg_temp(data_array)
    sum_high = data_array.map { |e| e[1].to_i }.reduce(:+)
    sum_low = data_array.map { |e| e[3].to_i }.reduce(:+)
    sum_humid = data_array.map { |e| e[7].to_i }.reduce(:+)
    [sum_high, sum_low, sum_humid]
  end
end
puts WeatherMan.new.main_function
