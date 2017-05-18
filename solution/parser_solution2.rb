require 'csv'
require 'sqlite3'
require 'date'

# Reading the CSV file
companies = CSV.read("../TechCrunchcontinentalUSA.csv")

# Selecting only the 'web' companies
web_companies = companies.select { |el| el[3] == 'web' }

# Making a Hash so we can find duplicates
names = Hash.new(0)
web_companies.each { |el| names[el[1]] += 1 }

dups = names.select { |_, v| v > 1 }

# Iterate over the duplicate names
dups.keys.each do |k|

  # Select out the actual rows based on names that were duplicate
  set = web_companies.select{ |el| el[1] == k }

  # Make a set of dates from subset, find max, delete the rest
  max_date = set.map { |el| Date.parse(el[6]) }.max

  to_delete = set.select { |el| Date.parse(el[6]) != max_date }
  remaining = set.reject { |el| Date.parse(el[6]) != max_date }
  to_delete.each { |el| web_companies.delete(el) }

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
    to_delete_indices = []
    to_delete_dups.each { |el| to_delete_indices << web_companies.index(el) }
    to_delete_indices.each { |idx| web_companies.delete_at(idx) }
  end
end

# # Helper to print out remaining duplicates
#
# web_companies.each_with_index do |el, i|
#   next if i == web_companies.length - 1
#   if web_companies[i + 1][0] == el[0]
#     p el
#     p web_companies[i + 1]
#   end
# end
#
# # Helper to verify number
#
# p web_companies.map { |el| el[0] }.count
# p web_companies.map { |el| el[0] }.uniq.count


## Alternate Solution 3
# companies = companies.select { |arr| arr[3] == 'web' }
#
# companies = companies.chunk { |rows| rows[1] }.to_a
#                      .map { |companies| companies[1] }
#
# companies_result = []
#
# companies.each do |company|
#   current_round = []
#
#   company.each do |funding_round|
#     current_round = funding_round if current_round.empty?
#
#     if (Date.parse(funding_round[6]) <=> Date.parse(current_round[6])) == -1
#       current_round = funding_round
#     elsif (Date.parse(funding_round[6]) <=> Date.parse(current_round[6])).zero?
#       if funding_round[7].to_i > current_round[7].to_i
#         current_round = funding_round
#       end
#     end
#   end
#
#   companies_result << current_round
# end

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
