

def print_sub_hashes(hash_of_hashes, local_fname)
  hash_of_hashes.keys.each { |hash|  append_hash(local_fname, hash_of_hashes[hash])}
end

def append_hash(local_fname, hash)
  hash.sort.each { |key, value|  File.open(local_fname, 'a'){|file| file.write("#{key}: #{value} \n")}}
  File.open(local_fname, 'a'){|file| file.write("\n")}
end

def append_array(local_fname, array)
  array.sort.each { |item|  File.open(local_fname, 'a'){|file| file.write("#{item} \n")}}
  File.open(local_fname, 'a'){|file| file.write("\n")}
end