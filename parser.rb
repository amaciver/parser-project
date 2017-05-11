require 'csv'
require 'sqlite3'

begin

    db = SQLite3::Database.open "test.db"
    db.execute "CREATE TABLE IF NOT EXISTS Cars(Id INTEGER PRIMARY KEY,
        Name TEXT, Price INT)"
    db.execute "INSERT INTO Cars VALUES(1,'Audi',52642)"
    db.execute "INSERT INTO Cars VALUES(2,'Mercedes',57127)"
    db.execute "INSERT INTO Cars VALUES(3,'Skoda',9000)"
    db.execute "INSERT INTO Cars VALUES(4,'Volvo',29000)"
    db.execute "INSERT INTO Cars VALUES(5,'Bentley',350000)"
    db.execute "INSERT INTO Cars VALUES(6,'Citroen',21000)"
    db.execute "INSERT INTO Cars VALUES(7,'Hummer',41400)"
    db.execute "INSERT INTO Cars VALUES(8,'Volkswagen',21600)"

rescue SQLite3::Exception => e

    puts "Exception occurred"
    puts e

ensure
    db.close if db
end



arr_of_arrs = CSV.read("TechCrunchcontinentalUSA.csv")

# p arr_of_arrs[0]
# p arr_of_arrs[1]
# p arr_of_arrs[2]
# p arr_of_arrs[3]
# p arr_of_arrs[4]
# p arr_of_arrs[5]

p arr_of_arrs.map{ |el| el[5] }.uniq
# p arr_of_arrs.count{ |el| el.include?("AZ") }

#
