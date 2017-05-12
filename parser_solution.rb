require 'csv'
require 'sqlite3'

# Reading the CSV file
companies = CSV.read("TechCrunchcontinentalUSA.csv")
# companies.each { |el| p el if el[1] == "google" }

# Selecting only the 'web' companies
web_companies = companies.select { |el| el[3] == 'web' }

# Making a Hash so we can find duplicates
names = Hash.new(0)
web_companies.each { |el| names[el[1]] += 1 }

dups = names.select { |_, v| v > 1 }

# List of months for date comparison
MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

# Iterate over the duplicate names
dups.keys.each do |k|

  # Select out the actual rows based on names that were duplicate
  set = web_companies.select{ |el| el[1] == k }

  # Make a set of years from subset, find max using mod, delete the rest
  set_of_years = set.map { |el| el[6][-2..-1] }
  max_year = set_of_years.max_by { |x| (x.to_i - 17) % 100 }
  to_delete_year = set.select { |el| el[6][-2..-1] != max_year }
  remaining = set.reject { |el| el[6][-2..-1] != max_year }
  to_delete_year.each { |el| web_companies.delete(el) }

  # If there are duplicate entries with max year, compare by month
  if remaining.length > 1
    set_of_months_indexes = remaining.map { |el| MONTHS.index(el[6][-6..-4]) }
    max_month = MONTHS[set_of_months_indexes.max]
    to_delete_month = remaining.select { |el| el[6][-6..-4] != max_month }
    remaining = remaining.reject { |el| el[6][-6..-4] != max_month }
    to_delete_month.each { |el| web_companies.delete(el) }
  end

  # If there are still duplicate entries, compare by day
  if remaining.length > 1
    set_of_days = remaining.map { |el| el[6][0..-8] }
    max_day = set_of_days.max
    to_delete_day = remaining.select { |el| el[6][0..-8] != max_day }
    remaining = remaining.reject { |el| el[6][0..-8] != max_day }
    to_delete_day.each { |el| web_companies.delete(el) }
  end

  # If duplicates still remain, compare by amount
  if remaining.length > 1
    set_of_amts = remaining.map{ |el| el[7] }
    max_amt = set_of_amts.max
    to_delete_amt = remaining.select { |el| el[7] != max_amt }
    remaining = remaining.reject { |el| el[7] != max_amt }
    to_delete_amt.each { |el| web_companies.delete(el) }
  end

  # If there are STILL duplicates, just choose one
  if remaining.length > 1
    to_delete_dups = remaining.drop(1)
    to_delete_dups.each { |el| web_companies.delete(el) }
  end
end

# Helper to print out remaining duplicates

# web_companies.each_with_index do |el, i|
#   next if i == web_companies.length - 1
#   if web_companies[i + 1][0] == el[0]
#     p el
#     p web_companies[i + 1]
#   end
# end

# Helper to verify number

# p web_companies.map { |el| el[0] }.count
# p web_companies.map { |el| el[0] }.uniq.count

begin

  db = SQLite3::Database.open "companies.db"
  db.execute "DROP TABLE IF EXISTS Companies"
  db.execute "CREATE TABLE IF NOT EXISTS Companies(Id INTEGER PRIMARY KEY,
      Permalink TEXT, Company TEXT, NumEmps INT, Catergory TEXT, City TEXT, State TEXT, FundedDate TEXT,
      RaisedAmt INT, RaisedCurrency TEXT, Round TEXT)"


  # Start at index 1 so we can insert Primary Key by index, or similar
  (1..web_companies.length).each do |i|
    company = web_companies[i - 1]

    # Control for nil values which will cause exceptions
    company.map! { |el| el.nil? ? 0 : el }

    # Control for stray single quotes which will cause an exception
    company.each_with_index do |el, idx|
      company[idx] = el.delete("\'") if el.is_a?(String) && el.include?("\'")
    end

    # Print to track progress and examine where errors arise
    # p company

    # Make sure that values are entered as strings or integers according to schema
    db.execute "INSERT INTO Companies VALUES(#{i}, '#{company[0]}', '#{company[1]}', #{company[2]}, '#{company[3]}', '#{company[4]}', '#{company[5]}', '#{company[6]}', #{company[7].to_i}, '#{company[8]}', '#{company[9]}')"
  end

  # SELECT AVG(RaisedAmt), State, MAX(RaisedAmt), Company, MAX(RaisedAmt)-AVG(RaisedAmt) AS diff FROM Companies GROUP BY State ORDER BY diff DESC LIMIT 1;
  p db.execute "SELECT Company, MAX(RaisedAmt)-AVG(RaisedAmt) AS diff FROM Companies GROUP BY State ORDER BY diff DESC LIMIT 1"

rescue SQLite3::Exception => e

  puts "Exception occurred"
  puts e

ensure
  db.close if db
end
