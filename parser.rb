require 'csv'

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
