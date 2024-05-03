# Create project for synth/implementation

# Set directory for scripts, repo, ip
set scripts_dir [file normalize [file dirname [info script]]]
set origin_dir 	[file normalize $scripts_dir/..]
set ip_dir 		[file normalize $origin_dir/rtl]

# Create project folder
set projDir $origin_dir/project
file mkdir $projDir

# Create project file
set projName "pong"
set partName "xc7a100tcsg324-1"
create_project -part $partName -force $projName $projDir

# Set IP output directory
set ipOutputDir $projDir/$projName.gen/sources_1/ip
file mkdir $ipOutputDir

# Set default lib, language for netlists and models, automated compile order
set_property -dict { \
		default_lib			{top_lib} \
		target_language 	{VHDL} \
		simulator_language	{Mixed} \
		source_mgmt_mode	{All}} \
	[current_project]

# Prevent sources_1 files from going into sim_1 by default
set_property SOURCE_SET {} [get_filesets sim_1]

# Add RTL sources
add_files [glob $origin_dir/rtl/*.vhd]
set_property library top_lib [get_files [glob $origin_dir/rtl/*.vhd]]

# Set the top for synth
set_property -dict { \
	top 		{top} \
	top_lib 	{top_lib} \
	[get_filesets sources_1]
	
# Add constraints
set targetXDC $projDir/nexysa7_constraints.xdc
exec touch $targetXDC
set_property target_constrs_file $targetXDC [current_fileset -constrset]

# Set properties suggested by Xilinx
set_property -name "default_lib" -value "top_lib" -objects $obj
# Look up what line below does
set_property -name "platform.dr_bd_base_address" -value "0" -objects $obj 
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$projDir/${projName}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj

puts "Project file created"