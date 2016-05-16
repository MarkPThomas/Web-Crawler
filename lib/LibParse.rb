def strip_bullet_point(value)
  first_char = 0
  value.each_char { |c| c =~ /[A-Za-z]/ ? break : first_char += 1 }

  value[first_char...value.length]
end