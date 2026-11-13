# Get the directory where THIS script lives
set script_path [file normalize [file dirname [info script]]]

# Set a global variable so other scripts can see it
set ::hdl_projects_dir $script_path

# Optional: Set it in the OS environment so it's accessible everywhere
set ::env(HDL_PROJECTS_DIR) $script_path