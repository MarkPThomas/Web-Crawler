
def append_hash(local_fname, hash)

  begin
    hash.sort.each { |key, value|  File.open(local_fname, 'a'){|file| file.write("#{key}: #{value} \n")}}
    File.open(local_fname, 'a'){|file| file.write("\n")}
  rescue
    hash.each { |key, value|  File.open(local_fname, 'a'){|file| file.write("#{key}: #{value} \n")}}
    File.open(local_fname, 'a'){|file| file.write("\n")}
  end

end

def append_array(local_fname, array)
  array.sort.each { |item|  File.open(local_fname, 'a'){|file| file.write("#{item} \n")}}
  File.open(local_fname, 'a'){|file| file.write("\n")}
end