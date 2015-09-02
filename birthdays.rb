require 'date'
require 'optparse'
require 'ostruct'

require 'gmail'

# This class adds ordinal conversion capabilities to the Fixnum class.
class Fixnum
  def to_ord
    if (11..13).include?(self % 100)
      "#{self}th"
    else
      case self % 10
      when 1 then "#{self}st"
      when 2 then "#{self}nd"
      when 3 then "#{self}rd"
      else        "#{self}th"
      end
    end
  end
end

# Email class tailored to handle birthday emails.
class Email
  def initialize(pair, gmail)
    @pair = pair
    @gmail = gmail
  end

  def possessify(name)
    name + "'" + (name.end_with?('s') ? '' : 's')
  end

  def compose_body(pair, possessive)
    "Hi #{pair[0][:name]},\n" \
    "\n" \
    "You have been assigned to take care of #{possessive} " \
    'birthday present which takes place on the ' \
    "#{pair[1][:day].to_ord} of " \
    "#{Date::MONTHNAMES[pair[1][:month]]}. Please contact " \
    "me for further details.\n" \
    "\n" \
    "Thanks,\n" \
    'Vali'
  end

  def send!(username)
    pair = @pair
    possessive = possessify pair[1][:name]

    email_body = compose_body pair, possessive

    email = @gmail.generate_message do
      from username
      to pair[0][:email]
      subject "#{possessive} birthday"
      body email_body
    end

    email.deliver!
  end
end

def parse_people(lines)
  lines.map do |line|
    name, email, date = line.split(',').map(&:strip)
    day, month = date.split('.').map(&:to_i)

    { name: name, email: email, day: day, month: month }
  end
end

def parse_assigned(assigned_file, people)
  already_assigned = []

  unless assigned_file.eof?
    assigned_names = assigned_file.read.gsub(/\s+/, '').split(',')
    already_assigned = people.select do |person|
      assigned_names.include? person[:name]
    end
  end

  already_assigned
end

def assign(upcoming, remaining, assigned_file)
  upcoming.map do |person|
    assigned = remaining.sample
    remaining.delete assigned

    assigned_file.print "#{assigned[:name]},"

    [assigned, person]
  end
end

options = OpenStruct.new

options.dates = 'dates'
options.assigned = '.assigned'
options.month = DateTime.now.next_month.month

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby birthdays.rb -u USERNAME -p PASSWORD [OPTIONS]'

  opts.on(
    '-u',
    '--username USERNAME',
    'Gmail username'
  ) { |username| options.username = username }
  opts.on(
    '-p',
    '--password PASSWORD',
    'Gmail password'
  ) { |password| options.password = password }

  opts.on(
    '-d',
    '--dates PATH',
    'Path to dates file (default ./dates)'
  ) { |dates| options.dates = dates }
  opts.on(
    '-a',
    '--assigned PATH',
    'Path to assigned file (default ./.assigned)'
  ) { |assigned| options.assigned = assigned }
  opts.on(
    '-m',
    '--month MONTH',
    'Number of the month (default next month)'
  ) { |month| options.month = month.to_i }
end.parse!

missing = %w(username password).select { |opt| options.send(opt).nil? }
abort "Missing #{missing.join ', '}." unless missing.empty?

File.open options.dates do |dates|
  people = parse_people dates.readlines

  already_assigned = parse_assigned File.open(options.assigned), people

  upcoming = people.select { |person| person[:month] == options.month }
  remaining = people - upcoming - already_assigned

  if remaining.length < upcoming.length
    File.open(options.assigned, 'w') { |file| file.truncate 0 }

    remaining = people - upcoming
  end

  gmail = Gmail.new options.username, options.password

  assignments = assign upcoming, remaining, File.open(options.assigned, 'a')

  assignments.map { |pair| Email.new pair, gmail }
    .map { |email| email.send! options.username }
  assignments.each { |pair| puts "#{pair[0][:name]} -> #{pair[1][:name]}" }
end
