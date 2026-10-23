create_project Lab5_cache . -part xc7a35tcpg236-1 -force
add_files [list cache.v main_memory.v CPU.v Lab5_cache_test.v]
set_property top CacheTest [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral
