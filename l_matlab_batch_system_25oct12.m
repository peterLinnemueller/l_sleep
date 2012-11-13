c = parcluster('local'); % get the 'local' cluster object
job = batch(c, 'l_parallel_script_preproc_modular_19oct12_tmp'); % submit script for execution
% now edit 'myNNscript'
job2 = batch(c, 'l_parallel_script_preproc_modular_19oct12_tmp'); % submit script for execution
wait(job); load(job) % get the results