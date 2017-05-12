require 'csv'
require 'sqlite3'


companies = CSV.read("TechCrunchcontinentalUSA.csv")

web_companies = companies.select{ |el| el[3] == 'web'}

names = Hash.new(0)
web_companies.each { |el| names[el[1]] += 1 }

dups = names.select{ |k,v| v > 1 }

months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

dups.each do |k,v|
  set = web_companies.select{ |el| el[1] == k }
  set_of_years = set.map{ |el| el[6][-2..-1] }
  max_year = set_of_years.max
  to_delete_year = set.select{ |el| el[6][-2..-1] != max_year }
  remaining = set.reject{ |el| el[6][-2..-1] != max_year }
  to_delete_year.each{ |el| web_companies.delete(el) }

  if remaining.length > 1
    set_of_months_indexes = remaining.map{ |el| months.index(el[6][-6..-4]) }
    max_month = months[set_of_months_indexes.max]
    to_delete_month = remaining.select{ |el| el[6][-6..-4] != max_month }
    remaining = set.reject{ |el| el[6][-6..-4] != max_month }
    to_delete_month.each{ |el| web_companies.delete(el) }
  end

  if remaining.length > 1
    set_of_days = remaining.map{ |el| el[6][0..-8] }
    max_day = set_of_days.max
    to_delete_day = remaining.select{ |el| el[6][0..-8] != max_day }
    remaining = set.reject{ |el| el[6][0..-8] != max_day }
    to_delete_day.each{ |el| web_companies.delete(el) }
  end

  if remaining.length > 1
    set_of_amts = remaining.map{ |el| el[7] }
    max_amt = set_of_amts.max
    to_delete_amt = remaining.select{ |el| el[7] != max_amt }
    remaining = remaining.reject{ |el| el[7] != max_amt }
    to_delete_amt.each{ |el| web_companies.delete(el) }
  end

  if remaining.length > 1
    to_delete_dups = remaining.drop(1)
    to_delete_dups.each{ |el| web_companies.delete(el) }
  end
end

# 
# web_companies.each_with_index do |el, i|
#   next if i == web_companies.length - 1
#   if web_companies[i + 1][0] == el[0]
#     p el
#     p web_companies[i + 1]
#   end
# end

# p web_companies.map { |el| el[0] }.count
# p web_companies.map { |el| el[0] }.uniq.count

begin

  db = SQLite3::Database.open "companies.db"
  db.execute "CREATE TABLE IF NOT EXISTS Companies(Id INTEGER PRIMARY KEY,
      Permalink TEXT, Company TEXT, NumEmps INT, Catergory TEXT, City TEXT, State TEXT, FundedDate TEXT,
      RaisedAmt INT, RaisedCurrency TEXT, Round TEXT)"
  (1..web_companies.length).each do |i|
    company = web_companies[i-1]
    company.map! { |el| el.nil? ? 0 : el }
    company.each_with_index do |el, i|
      if el.is_a?(String) && el.include?("\'")
        company[i] = el.delete("\'")
        p el
      end
    end
    p company
    db.execute "INSERT INTO Companies VALUES(#{i}, '#{company[0]}', '#{company[1]}', #{company[2]}, '#{company[3]}', '#{company[4]}', '#{company[5]}', '#{company[6]}', #{company[7].to_i}, '#{company[8]}', '#{company[9]}')"
  end


rescue SQLite3::Exception => e

  puts "Exception occurred"
  puts e

ensure
    db.close if db
end





# p arr_of_arrs[0]
# p arr_of_arrs[1]
# p arr_of_arrs[2]
# p arr_of_arrs[3]
# p arr_of_arrs[4]
# p arr_of_arrs[5]

# p companies
# p companies.map{ |el| el[5] }.uniq
# p companies.count{ |el| el.include?("AZ") }

#
