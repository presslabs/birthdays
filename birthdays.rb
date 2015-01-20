require 'date'
require 'gmail'

module Email
  USERNAME = "username"
  PASSWORD = "password"
end

class Fixnum
  def ordinalize
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

def send_email(pair)
  gmail = Gmail.new Email::USERNAME, Email::PASSWORD

  possessive = pair[1][:name] + "'" + (pair[1][:name].end_with?("s") ? "" : "s")

  email_body = "Hi #{pair[0][:name]},\n" \
               "\n" \
               "You have been assigned to take care of #{possessive} " \
               "birthday present which takes place on the " \
               "#{pair[1][:day].ordinalize} of " \
               "#{Date::MONTHNAMES[pair[1][:month]]}.\n" \
               "\n" \
               "Thanks,\n" \
               "Vali"

  email = gmail.generate_message do
    from Email::USERNAME
    to pair[0][:email]
    subject "#{possessive} birthday"
    body email_body
  end

  email.deliver!
end

File.open("dates") do |dates|
  people = []
  assignments = []
  lines = dates.readlines

  lines.each do |line|
    name, email, date = line.split(",").map {|token| token.strip}
    day, month = date.split(".").map {|number| number.to_i}

    people << {name: name, email: email, day: day, month: month}
  end

  next_month = DateTime.now.next_month.month

  already_assigned = []

  File.open(".assigned") do |assigned_file|
    unless assigned_file.eof?
      assigned_names = assigned_file.readline.strip.split(",")
      already_assigned = people.select {|person| assigned_names.include? person[:name]}
    end
  end

  upcoming = people.select {|person| person[:month] == next_month}
  remaining = people - upcoming - already_assigned

  if remaining.empty?
    File.open(".assigned", "w") {|file| file.truncate(0)}

    remaining = people - upcoming
  end

  File.open(".assigned", "a") do |assigned_file|
    upcoming.each do |person|
      assigned = remaining.sample
      remaining.delete assigned

      assigned_file.print "#{assigned[:name]},"

      assignments << [assigned, person]
    end
  end

  assignments.each {|pair| send_email pair}

  assignments.each {|pair| puts "#{pair[0][:name]} -> #{pair[1][:name]}"}
end
