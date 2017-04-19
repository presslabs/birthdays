# Birthdays

Birthdays is a little Ruby script that automatically sends birthday reminders conforming to Presslabs' birthday policy.

Features:

  * randomly picks person to do the gifting
  * keeps track of people in order not to have one person do the gifting more than once a year
  * automatically sends reminders from a Gmail address
  * uses a simple CSV file to input everyone's birthdays and emails

## Installation

```
# Ruby

sudo apt-get install ruby

# Bundler

sudo apt-get install bundler

# Dependencies

bundle install
```

## Usage

Run `ruby birthdays.rb -h` for details on how to use the CLI.

The script uses a separate file to keep track of the team and their birthdays of the form:

```
John, john@me.com, 21.03
Emily, emily@you.com, 17.11
```
