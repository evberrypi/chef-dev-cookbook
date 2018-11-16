name "development-role"
description "this role is for development access"
run_list "recipe[apt]", "recipe[habitat]"
