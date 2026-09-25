M = load_etabs_model({'gg.txt'});                % if everything is in one file


[res, chk] = joint_forces(M, '10');
res = res(strcmp({res.ctype}, 'Combination'));    % keep only combinations
print_joint_forces(res, chk, '10');
