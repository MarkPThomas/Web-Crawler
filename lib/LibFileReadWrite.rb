def overwrite_sub_hashes(hash_of_hashes, local_fname)
  File.delete(local_fname) if File.exist?(local_fname)
  sleep(0.2)
  append_sub_hashes(hash_of_hashes, local_fname)
end

def append_sub_hashes(hash_of_hashes, local_fname)
  hashes_num = 1
  hashes_max = hash_of_hashes.size
  hash_of_hashes.keys.each { |hash|
    puts "Writing item #{hashes_num} of #{hashes_max}"
    append_hash(hash_of_hashes[hash], local_fname)
    hashes_num += 1
  }
end


def overwrite_hash(hash, local_fname)
  File.delete(local_fname) if File.exist?(local_fname)
  sleep(0.2)
  append_hash(hash, local_fname)
end

def append_hash(hash, local_fname)
  puts "Writing to file #{local_fname}"
  begin
    hash.sort.each { |key, value|  File.open(local_fname, 'a'){|file| file.write("#{key}: #{value} \n")}}
  rescue
    hash.each { |key, value|  File.open(local_fname, 'a'){|file| file.write("#{key}: #{value} \n")}}
  end
  File.open(local_fname, 'a'){|file| file.write("\n")}

end


def overwrite_array(array, local_fname)
  File.delete(local_fname) if File.exist?(local_fname)
  sleep(0.2)
  append_array(array, local_fname)
end

def append_array(array, local_fname)
  puts "Writing to file #{local_fname}"
  array.sort.each { |item|  File.open(local_fname, 'a'){|file| file.write("#{item} \n")}}
  File.open(local_fname, 'a'){|file| file.write("\n")}
end

