function print_joint_forces(res, chk, joint)
% PRINT_JOINT_FORCES  Screen output of joint_forces results.
  fprintf('\n=== Joint %s ===\n', joint);
  fprintf('A) Member end forces, member local axes, ETABS sign convention\n');
  fprintf('%-8s %-6s %-3s %-28s %10s %10s %10s %10s %10s %10s\n', ...
          'Frame','Type','End','Case','P','V2','V3','T','M2','M3');
  for k = 1:numel(res)
    fprintf('%-8s %-6s %-3s %-28s %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f\n', ...
      res(k).frame, res(k).type, res(k).endIJ, res(k).ocase, res(k).loc);
  end
  fprintf('\nB) Forces exerted BY each member ON the joint, axes: %s\n', res(1).refAxes);
  fprintf('%-8s %-6s %-3s %-28s %10s %10s %10s %10s %10s %10s\n', ...
          'Frame','Type','End','Case','F1','F2','F3','M1','M2','M3');
  for k = 1:numel(res)
    fprintf('%-8s %-6s %-3s %-28s %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f\n', ...
      res(k).frame, res(k).type, res(k).endIJ, res(k).ocase, res(k).ref);
  end
  fprintf('\nC) Equilibrium check (global, sum over members, moments about joint)\n');
  for c = 1:numel(chk)
    fprintf('%-28s  sumF = [%9.3f %9.3f %9.3f]  sumM = [%9.3f %9.3f %9.3f]\n', ...
            chk(c).ocase, chk(c).sumF, chk(c).sumM);
  end
end
