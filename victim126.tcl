run 126 ns
puts "req [get_value /vm_test/CPU/request_num]"
puts "vpn [get_value /vm_test/TLB/vpn]"
puts "victim [get_value /vm_test/TLB/victim_idx]"
puts "hit [get_value /vm_test/TLB/hit]"
puts "hit_idx [get_value /vm_test/TLB/hit_idx]"
puts "ages [get_value /vm_test/TLB/age]"
puts "valids [get_value /vm_test/TLB/valid]"
puts "tags [get_value /vm_test/TLB/tag]"
quit
