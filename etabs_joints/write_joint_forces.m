function write_joint_forces(res, fname)
% WRITE_JOINT_FORCES  Save joint_forces results to CSV (opens in Excel).
  fid = fopen(fname, 'w');
  fprintf(fid, ['Frame,Type,End,Case,Station,P,V2,V3,T,M2,M3,' ...
                'Fx_glob,Fy_glob,Fz_glob,Mx_glob,My_glob,Mz_glob,' ...
                'F1_ref,F2_ref,F3_ref,M1_ref,M2_ref,M3_ref,RefAxes\n']);
  for k = 1:numel(res)
    fprintf(fid, '%s,%s,%s,%s,%.4f', res(k).frame, res(k).type, ...
            res(k).endIJ, res(k).ocase, res(k).station);
    fprintf(fid, ',%.4f', [res(k).loc res(k).glob res(k).ref]);
    fprintf(fid, ',%s\n', res(k).refAxes);
  end
  fclose(fid);
end
